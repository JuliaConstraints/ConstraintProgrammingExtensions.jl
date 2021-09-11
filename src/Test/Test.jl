module Test

using Test
using MathOptInterface
using ConstraintProgrammingExtensions

const MOI = MathOptInterface
const MOIU = MOI.Utilities
const MOIT = MOI.DeprecatedTest
const CP = ConstraintProgrammingExtensions

# Test sets.
include("alldifferent.jl")
include("antidomain.jl")
include("binpacking.jl")
include("count.jl")
include("countdistinct.jl")
include("differentfrom.jl")
include("domain.jl")
include("element.jl")
include("equivalence.jl")
include("equivalencenot.jl")
include("ifthenelse.jl")
include("implication.jl")
include("indicator.jl")
include("inverse.jl")
include("lexicographically.jl")
include("minimumdistance.jl")
include("reification.jl")
include("strictly.jl")
include("strictly_lexicographically.jl")
include("truefalse.jl")

end
