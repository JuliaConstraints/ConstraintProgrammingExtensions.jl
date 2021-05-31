include("BinPacking/fixedcapa_to_bp.jl")
const FixedCapacityBinPacking2BinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{FixedCapacityBinPacking2BinPackingBridge{T}, OT}
    
include("BinPacking/fixedcapa_to_varcapa.jl")
const FixedCapacityBinPacking2VariableCapacityBinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}, OT}
    
include("BinPacking/bp_to_milp.jl")
const BinPacking2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{BinPacking2MILPBridge{T}, OT}
    
include("BinPacking/varcapa_to_milp.jl")
const VariableCapacityBinPacking2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VariableCapacityBinPacking2MILPBridge{T}, OT}
    
include("Knapsack/kp_to_varcapa.jl")
const Knapsack2VariableCapacityKnapsack{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Knapsack2VariableCapacityKnapsackBridge{T}, OT}
    
include("Knapsack/kp_to_milp.jl")
const Knapsack2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Knapsack2MILPBridge{T}, OT}
    
include("Knapsack/varcapa_to_milp.jl")
const VariableCapacityKnapsack2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VariableCapacityKnapsack2MILPBridge{T}, OT}
