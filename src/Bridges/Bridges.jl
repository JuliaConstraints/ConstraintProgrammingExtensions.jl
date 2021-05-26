module Bridges

using MathOptInterface
using ConstraintProgrammingExtensions
const CP = ConstraintProgrammingExtensions
const MOI = MathOptInterface
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges
const MOIBC = MOIB.Constraint

include("set_fixedcapacitybinpacking.jl")
const FixedCapacityBinPacking2BinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{FixedCapacityBinPacking2BinPackingBridge{T}, OT}

end
