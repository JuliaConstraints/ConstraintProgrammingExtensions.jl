module Bridges

using LinearAlgebra

using MathOptInterface
using ConstraintProgrammingExtensions
const CP = ConstraintProgrammingExtensions
const MOI = MathOptInterface
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges
const MOIBC = MOIB.Constraint

include("helpers.jl")
include("Constraint/Constraint.jl")
# include("Function/Function.jl")

end
