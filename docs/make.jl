using Documenter, ConstraintProgrammingExtensions

# More than inspired by https://github.com/jump-dev/MathOptInterface.jl/blob/master/docs/make.jl.

makedocs(
    sitename="ConstraintProgrammingExtensions",
    format=Documenter.HTML(
        # See https://github.com/JuliaDocs/Documenter.jl/issues/868
        prettyurls=get(ENV, "CI", nothing) == "true",
        mathengine=Documenter.MathJax2(),
        collapselevel=1,
    ),
    strict=true,
    modules=[ConstraintProgrammingExtensions],
    checkdocs=:exports,
    pages=[
        "Introduction" => "index.md",
        "Reference" => ["reference/sets.md", "reference/bridges_sets.md"],
        "Comparison to other CP packages" => [
            "mappings/constraintsolver.md",
            "mappings/cplexcp.md",
            "mappings/disjunctive.md",
            "mappings/facile.md",
            "mappings/hakank.md",
            "mappings/juliaconstraints.md",
            "mappings/minizinc.md",
            "mappings/numberjack.md",
            "mappings/sas.md",
            "mappings/yalmip.md",
        ],
    ],
)

deploydocs(
    push_preview=true,
    repo="github.com/JuliaConstraints/ConstraintProgrammingExtensions.jl.git",
)
