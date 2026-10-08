/*
 * Animates the hum wave in the ground loop logo. At exponentially spaced
 * intervals the wave picks up about a second of interference (drifting
 * mains harmonics, band-limited noise, hiss and clicks), then returns to
 * the static path.
 *
 * Attaches to every `svg [data-hum]` path; the logo must be inline SVG.
 */

const X0 = 44;
const X1 = 108;
const YC = 54;
const PERIOD = 32;
const AMP = 5.5;
const LIMIT = 13; // soft-clip ceiling; the box's inner edge is ~32 units from YC
const STEP = 0.5;

const MEAN_WAIT = 9000;
const MIN_WAIT = 2500;
const BURST_MS = [800, 1600];
const INTENSITY = 1;

const TAU = Math.PI * 2;
const rnd = Math.random;

const expo = (mean) => -mean * Math.log(1 - rnd());

function gauss() {
  const u = 1 - rnd();
  const v = rnd();
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(TAU * v);
}

const smooth = (t) => (t <= 0 ? 0 : t >= 1 ? 1 : t * t * (3 - 2 * t));

function valueNoise(lattice, x) {
  const n = lattice.length;
  const i = Math.floor(x);
  const a = lattice[((i % n) + n) % n];
  const b = lattice[(((i + 1) % n) + n) % n];
  return a + (b - a) * smooth(x - i);
}

function lattice(n) {
  const a = new Float32Array(n);
  for (let i = 0; i < n; i++) a[i] = gauss() * 0.6;
  return a;
}

const sign = () => (rnd() < 0.5 ? -1 : 1);

function makeBurst(now) {
  const [dMin, dMax] = BURST_MS;
  // About a quarter of the harmonics are absent in any one burst.
  const harmonics = [2, 3, 4, 5, 7, 9].map((k) => ({
    k,
    a: (rnd() < 0.75 ? 1 : 0) * (0.2 + 0.8 * rnd()) * AMP * 0.55 * INTENSITY / Math.sqrt(k),
    phi: rnd() * TAU,
    drift: (rnd() - 0.5) * 2 * TAU * 2.5, // +/-2.5 Hz
  }));
  const clicks = Array.from({ length: Math.floor(rnd() * 4) }, () => ({
    x: X0 + 8 + (X1 - X0 - 16) * rnd(),
    t: 0.15 + 0.7 * rnd(),
    a: sign() * (6 + 6 * rnd()) * INTENSITY,
  }));
  return {
    start: now,
    length: dMin + (dMax - dMin) * rnd(),
    harmonics,
    coarse: lattice(32),
    fine: lattice(64),
    vCoarse: sign() * (1.5 + 3 * rnd()), // lattice cells/s
    vFine: sign() * (6 + 10 * rnd()),
    hiss: (0.3 + 0.5 * rnd()) * INTENSITY,
    clicks,
    swell: 0.2 + 0.5 * rnd(),
  };
}

// Attack over the first 15% of the burst, release over the last 35%.
function envelope(u) {
  if (u < 0.15) return smooth(u / 0.15);
  if (u > 0.65) return smooth((1 - u) / 0.35);
  return 1;
}

function wavePath(b, now) {
  const u = (now - b.start) / b.length;
  const m = envelope(u);
  const t = (now - b.start) / 1000;
  let d = "";
  for (let x = X0; x <= X1 + 1e-6; x += STEP) {
    const p = (x - X0) / PERIOD;
    let y = AMP * Math.sin(TAU * p);
    if (m > 0) {
      y *= 1 + b.swell * m;
      let n = 0;
      for (const h of b.harmonics) n += h.a * Math.sin(TAU * h.k * p + h.phi + h.drift * t);
      n += 4.0 * valueNoise(b.coarse, (x - X0) / 6 + b.vCoarse * t);
      n += 1.8 * valueNoise(b.fine, (x - X0) / 1.6 + b.vFine * t);
      n += b.hiss * gauss();
      for (const c of b.clicks) {
        const dt = (u - c.t) / 0.05;
        const dx = (x - c.x) / 1.4;
        n += c.a * Math.exp(-dt * dt - dx * dx);
      }
      // The taper pins the endpoints to the center line.
      const taper = Math.sin((Math.PI * (x - X0)) / (X1 - X0));
      y += m * n * Math.sqrt(taper);
      y = LIMIT * Math.tanh(y / LIMIT);
    }
    // SVG y grows downward; the static wave rises first.
    d += (d ? "L" : "M") + x.toFixed(2) + " " + (YC - y).toFixed(2);
  }
  return d;
}

function attach(path) {
  const original = path.getAttribute("d");
  const reduced = matchMedia("(prefers-reduced-motion: reduce)");
  let visible = true;
  let burst = null;

  new IntersectionObserver((es) => {
    visible = es.some((e) => e.isIntersecting);
  }).observe(path.ownerSVGElement);

  function tick(now) {
    if (now - burst.start >= burst.length) {
      burst = null;
      path.setAttribute("d", original);
      return;
    }
    path.setAttribute("d", wavePath(burst, now));
    requestAnimationFrame(tick);
  }

  function schedule() {
    setTimeout(() => {
      if (!burst && visible && !document.hidden && !reduced.matches) {
        burst = makeBurst(performance.now());
        requestAnimationFrame(tick);
      }
      schedule();
    }, MIN_WAIT + expo(MEAN_WAIT - MIN_WAIT));
  }

  schedule();
}

document.querySelectorAll("svg [data-hum]").forEach(attach);
