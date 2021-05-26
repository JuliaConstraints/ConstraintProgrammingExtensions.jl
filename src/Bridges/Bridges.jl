module Bridges

using MathOptInterface
using ConstraintProgrammingExtensions
const CP = ConstraintProgrammingExtensions
const MOI = MathOptInterface
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges
const MOIBC = MOIB.Constraint

include("set_fixedcapacitybinpacking.jl")

end
