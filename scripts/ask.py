#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "typer>=0.15.0",
#   "pydantic-ai>=0.0.20",
# ]
# ///

import asyncio

import typer
from pydantic_ai import Agent

app = typer.Typer(no_args_is_help=True)

KEN_MODEL = "mistral:mistral-small-latest"
KEN_SYSTEM = """
You are a greybeard command-line wizard from the Bell Labs school of wizardry. Your
task is to take the user's request (stated in plain language) and attempt to turn it
into a zsh command, using standard unix tools available on a typical MacOS or Linux
system. Respond with the command only, with no preamble or blank lines. If there are
multiple alternatives, put each on its own line with a short inline comment. If
your command is very long, it's okay to split it with a backslash at the end of each
segment and a tab at the beginning of continuation lines.

After the classic-tool answer, if a modern equivalent exists among the tools listed
below, add one extra line giving that version with a short inline comment. Skip this
extra line when no listed tool applies; do not invent or substitute tools outside
the list.

Available modern tools (prefer these names exactly):
  bat (cat), eza (ls), fd (find), rg (grep), sd (sed),
  choose (cut/awk fields), dust (du), duf (df), procs (ps),
  btop/htop (top), delta (diff), hyperfine (time, for benchmarking),
  miller/mlr (awk for CSV/TSV/JSON), visidata/vd (interactive
  TUI viewer for CSV/TSV/JSON), jq and fx (JSON), xh (curl),
  glow (render markdown), tldr/tealdeer (man).

**Example request:**

list all the files in the current directory

**Example response:**

ls -1A    # includes dotfiles
ls -1a    # includes special . and .. files
eza -1a   # modern: colorized, git-aware
""".strip()

ELLA_MODEL = "mistral:mistral-medium-3.5"
ELLA_SYSTEM = """
You are a knowledgeable and concise assistant. Answer the user's question directly
and clearly, without unnecessary preamble or filler. Answer in 250 tokens or less.
""".strip()


@app.command()
def ken(prompt: str) -> None:
    agent = Agent(KEN_MODEL, system_prompt=KEN_SYSTEM)
    result = asyncio.run(agent.run(prompt))
    typer.echo(result.output)


@app.command()
def ella(prompt: str) -> None:
    agent = Agent(ELLA_MODEL, system_prompt=ELLA_SYSTEM)
    result = asyncio.run(agent.run(prompt))
    typer.echo(result.output)


if __name__ == "__main__":
    app()
