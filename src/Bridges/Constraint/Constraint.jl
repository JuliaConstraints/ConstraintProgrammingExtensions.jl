include("BinPacking/fixedcapa_to_bp.jl")
const FixedCapacityBinPacking2BinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{FixedCapacityBinPacking2BinPackingBridge{T}, OT}
    
include("BinPacking/fixedcapa_to_varcapa.jl")
const FixedCapacityBinPacking2VariableCapacityBinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}, OT}
    
include("BinPacking/bp_to_milp.jl")
const BinPacking2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{BinPacking2MILPBridge{T}, OT}
    
include("BinPacking/varcapa_to_bp.jl")
const VariableCapacityBinPacking2BinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VariableCapacityBinPacking2BinPackingBridge{T}, OT}
    
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

include("Knapsack/vkp_to_kp.jl")
const ValuedKnapsack2Knapsack{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ValuedKnapsack2KnapsackBridge{T}, OT}

include("Knapsack/varcapav_to_varcapa.jl")
const VariableCapacityValuedKnapsack2VariableCapacityKnapsack{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T}, OT}

include("AllDifferent/ad_to_neq.jl")
const AllDifferent2DifferentFrom{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AllDifferent2DifferentFromBridge{T}, OT}
