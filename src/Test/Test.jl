module Test

using Test
using MathOptInterface
using ConstraintProgrammingExtensions

const MOI = MathOptInterface
const MOIU = MOI.Utilities
const MOIT = MOI.Test
const CP = ConstraintProgrammingExtensions

# A few helpers
function _vov(vars::Vector{MOI.VariableIndex})
    return MOI.VectorOfVariables(vars)
end

function _saf(var::MOI.VariableIndex)
    return MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1], [var]), 0)
end

function _saf(vars::Vector{MOI.VariableIndex})
    return _saf(ones(Int, length(vars)), vars)
end

function _saf(coeffs::Vector{Int}, vars::Vector{MOI.VariableIndex})
    @assert length(coeffs) == length(vars)
    return MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(coeffs, vars), 0)
end

function _vaf(vars::Vector{MOI.VariableIndex})
    return MOI.VectorAffineFunction(
        MOI.VectorAffineTerm.(
            collect(1:length(vars)),
            MOI.ScalarAffineTerm.(ones(Int, length(vars)), vars),
        ),
        zeros(Int, length(vars)),
    )
end

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
include("imply.jl")
include("inverse.jl")
include("lexicographically.jl")
include("minimumdistance.jl")
include("reified.jl")
include("strictly.jl")
include("strictly_lexicographically.jl")
include("truefalse.jl")

end
