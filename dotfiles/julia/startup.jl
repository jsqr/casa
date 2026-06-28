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
        OhMyREPL.colorscheme!("GruvboxDark")
    catch
        @warn "startup.jl: OhMyREPL not installed — skipping"
    end

    try
        using BenchmarkTools
    catch
        @warn "startup.jl: BenchmarkTools not installed — skipping"
    end
end
