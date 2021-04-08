module Test

using Test
using MathOptInterface

const MOI = MathOptInterface
const MOIU = MOI.Utilities
const MOIT = MOI.Test

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
include("domain.jl")

end