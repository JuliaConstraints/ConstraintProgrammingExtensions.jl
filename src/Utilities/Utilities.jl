module Utilities

using MathOptInterface
using ConstraintProgrammingExtensions

const MOI = MathOptInterface
const MOIU = MOI.Utilities
const MOIT = MOI.Test
const CP = ConstraintProgrammingExtensions

#include("model.jl")

end
