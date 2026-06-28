# ~/.julia/config/startup.jl — runs at the start of every Julia process.
#
# Deployed by Nix, but the packages are managed by the global Pkg environment
# (~/.julia/environments/v#.#), not Nix. Provision them with:
#
#   julia> import Pkg; Pkg.add(["Revise", "OhMyREPL", "BenchmarkTools"])

try
    using Revise
catch
    @warn "startup.jl: Revise not installed — skipping"
end

# REPL-only: skip for scripts, `julia -e`, and test workers
if isinteractive()
    try
        using OhMyREPL
        import OhMyREPL.Passes.SyntaxHighlighter as SH
        # Kanagawa Dragon palette mapped onto OhMyREPL token types.
        let scheme = SH.ColorScheme(), C = SH.Crayons.Crayon
            SH.text!(scheme,         C(foreground = 0xc5c9c5))  # dragonWhite
            SH.comment!(scheme,      C(foreground = 0x737c73))  # dragonAsh
            SH.string!(scheme,       C(foreground = 0x8a9a7b))  # dragonGreen2
            SH.keyword!(scheme,      C(foreground = 0x8992a7))  # dragonViolet
            SH.number!(scheme,       C(foreground = 0xa292a3))  # dragonPink
            SH.function_def!(scheme, C(foreground = 0x8ba4b0))  # dragonBlue2
            SH.call!(scheme,         C(foreground = 0x8ba4b0))  # dragonBlue2
            SH.op!(scheme,           C(foreground = 0xc4746e))  # dragonRed
            SH.macro!(scheme,        C(foreground = 0xc4746e))  # dragonRed
            SH.symbol!(scheme,       C(foreground = 0xc4b28a))  # dragonYellow
            SH.argdef!(scheme,       C(foreground = 0xa6a69c))  # dragonGray
            SH.error!(scheme,        C(foreground = :default, background = :light_red))
            SH.add!("KanagawaDragon", scheme)
        end
        OhMyREPL.colorscheme!("KanagawaDragon")
    catch
        @warn "startup.jl: OhMyREPL not available — skipping theme"
    end

    try
        using BenchmarkTools
    catch
        @warn "startup.jl: BenchmarkTools not installed — skipping"
    end
end
