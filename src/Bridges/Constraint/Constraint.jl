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
    MOIBC.SingleBridgeOptimizer{VariableCapacityValuedKnapsack2VariableCapacityKnapsackBridge{T}, OT}

include("AllDifferent/ad_to_neq.jl")
const AllDifferent2DifferentFrom{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AllDifferent2DifferentFromBridge{T}, OT}

include("AbsoluteValue/abs_to_milp.jl")
const AbsoluteValue2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AbsoluteValue2MILPBridge{T}, OT}

include("DifferentFrom/neq_to_pseudolp.jl")
const DifferentFrom2PseudoMILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{DifferentFrom2PseudoMILPBridge{T}, OT}

include("Strictly/strictly_to_lp.jl")
const Strictly2Linear{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Strictly2LinearBridge{T}, OT}

include("AllEqual/alleq_to_eq.jl")
const AllEqual2EqualTo{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AllEqual2EqualToBridge{T}, OT}

include("MaximumAmong/max_to_milp.jl")
const MaximumAmong2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{MaximumAmong2MILPBridge{T}, OT}

include("MinimumAmong/min_to_milp.jl")
const MinimumAmong2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{MinimumAmong2MILPBridge{T}, OT}

include("ArgumentMaximumAmong/argmax_to_milp.jl")
const ArgumentMaximumAmong2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ArgumentMaximumAmong2MILPBridge{T}, OT}

include("ArgumentMinimumAmong/argmin_to_milp.jl")
const ArgumentMinimumAmong2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ArgumentMinimumAmong2MILPBridge{T}, OT}

include("SortPermutation/perm_to_alldiff_indexing.jl")
const SortPermutation2AllDifferent{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{SortPermutation2AllDifferentBridge{T}, OT}

include("Sort/sort_to_perm.jl")
const Sort2SortPermutation{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Sort2SortPermutationBridge{T}, OT}

include("Sort/sort_to_milp.jl")
const Sort2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Sort2MILPBridge{T}, OT}
