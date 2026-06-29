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

    # Debugger.jl colors its source listing via Highlights.jl (not OhMyREPL),
    # defaulting to a bright Monokai theme. Re-theme to Kanagawa Dragon when
    # Debugger loads — it's pulled in per-project, not at startup.
    push!(Base.package_callbacks, function (pkg)
        pkg.name == "Debugger" || return
        try
            # Split eval: the `using` must run before the @theme/S"" macros below
            # are expanded, so they can't share one block.
            @eval using Debugger, Debugger.Highlights.Themes, Debugger.Highlights.Tokens
            @eval begin
                abstract type KanagawaDragonTheme <: AbstractTheme end
                @theme KanagawaDragonTheme Dict(
                    :name   => "KanagawaDragon",
                    :style  => S"",
                    :tokens => Dict(
                        COMMENT           => S"fg: 737c73",  # dragonAsh
                        KEYWORD           => S"fg: 8992a7",  # dragonViolet
                        KEYWORD_NAMESPACE => S"fg: c4746e",  # dragonRed
                        KEYWORD_TYPE      => S"fg: 8ea4a2",  # dragonAqua
                        OPERATOR          => S"fg: c4746e",  # dragonRed
                        NAME_FUNCTION     => S"fg: 8ba4b0",  # dragonBlue2
                        NAME_CLASS        => S"fg: 8ba4b0",
                        NAME_DECORATOR    => S"fg: c4746e",
                        NAME_CONSTANT     => S"fg: b6927b",  # dragonOrange
                        NUMBER            => S"fg: a292a3",  # dragonPink
                        LITERAL           => S"fg: a292a3",
                        STRING            => S"fg: 8a9a7b",  # dragonGreen2
                        STRING_ESCAPE     => S"fg: a292a3",
                        ERROR             => S"fg: c4746e",
                    )
                )
                Debugger.set_theme(KanagawaDragonTheme)
                Debugger.set_highlight(Debugger.HIGHLIGHT_24_BIT)
            end
        catch e
            @warn "startup.jl: failed to theme Debugger" exception = e
        end
    end)
end
