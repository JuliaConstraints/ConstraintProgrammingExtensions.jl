include("AbsoluteValue/abs_to_milp.jl")
const AbsoluteValue2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AbsoluteValue2MILPBridge{T}, OT}

include("AllDifferent/ad_to_neq.jl")
const AllDifferent2DifferentFrom{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AllDifferent2DifferentFromBridge{T}, OT}

include("AllDifferentExceptConstants/adec_to_disjunction.jl")
const AllDifferentExceptConstants2ConjunctionDisjunction{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T}, OT}

include("AllEqual/alleq_to_eq.jl")
const AllEqual2EqualTo{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AllEqual2EqualToBridge{T}, OT}

include("ArgumentMaximumAmong/argmax_to_milp.jl")
const ArgumentMaximumAmong2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ArgumentMaximumAmong2MILPBridge{T}, OT}

include("ArgumentMinimumAmong/argmin_to_milp.jl")
const ArgumentMinimumAmong2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ArgumentMinimumAmong2MILPBridge{T}, OT}
    
include("BinPacking/bp_to_milp.jl")
const BinPacking2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{BinPacking2MILPBridge{T}, OT}

include("BinPacking/fixedcapa_to_bp.jl")
const FixedCapacityBinPacking2BinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{FixedCapacityBinPacking2BinPackingBridge{T}, OT}
    
include("BinPacking/fixedcapa_to_varcapa.jl")
const FixedCapacityBinPacking2VariableCapacityBinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}, OT}
    
include("BinPacking/varcapa_to_bp.jl")
const VariableCapacityBinPacking2BinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VariableCapacityBinPacking2BinPackingBridge{T}, OT}
    
include("BinPacking/varcapa_to_milp.jl")
const VariableCapacityBinPacking2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VariableCapacityBinPacking2MILPBridge{T}, OT}

include("ClosedGlobalCardinality/cgc_to_gc.jl")
const ClosedGlobalCardinality2GlobalCardinality{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ClosedGlobalCardinality2GlobalCardinalityBridge{T}, OT}

include("ClosedGlobalCardinalityVariable/cgcv_to_gcv.jl")
const ClosedGlobalCardinalityVariable2GlobalCardinalityVariable{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T}, OT}

include("Conjunction/conjunction_to_reif.jl")
const Conjunction2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Conjunction2ReificationBridge{T}, OT}

include("Count/count_to_reif.jl")
const CountEqualTo2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Count2ReificationBridge{T, MOI.EqualTo{T}}, OT}
const CountLessThan2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Count2ReificationBridge{T, MOI.LessThan{T}}, OT}
const CountGreaterThan2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Count2ReificationBridge{T, MOI.GreaterThan{T}}, OT}
const CountStrictlyLessThan2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Count2ReificationBridge{T, CP.Strictly{MOI.LessThan{T}, T}}, OT}
const CountStrictlyGreaterThan2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Count2ReificationBridge{T, CP.Strictly{MOI.GreaterThan{T}, T}}, OT}
const CountDifferentFrom2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Count2ReificationBridge{T, CP.DifferentFrom{T}}, OT}

include("CountCompare/countcmp_to_count.jl")
const CountCompare2Count{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{CountCompare2CountBridge{T}, OT}

include("Decreasing/dec_to_lp.jl")
const Decreasing2LP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Decreasing2LPBridge{T}, OT}

include("DifferentFrom/neq_to_pseudolp.jl")
const DifferentFrom2PseudoMILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{DifferentFrom2PseudoMILPBridge{T}, OT}

include("DifferentFrom_Indicator/neq_indicator0_to_pseudolp.jl")
const Indicator0DifferentFrom2PseudoMILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Indicator0DifferentFrom2PseudoMILPBridge{T}, OT}

include("DifferentFrom_Indicator/neq_indicator1_to_pseudolp.jl")
const Indicator1DifferentFrom2PseudoMILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Indicator1DifferentFrom2PseudoMILPBridge{T}, OT}

include("Disjunction/disjunction_to_reif.jl")
const Disjunction2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Disjunction2ReificationBridge{T}, OT}

include("Domain/domain_to_milp.jl")
const Domain2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Domain2MILPBridge{T}, OT}

include("DoublyLexicographicallyLessThan/dllt_to_llt.jl")
const DoublyLexicographicallyLessThan2LexicographicallyLessThan{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}, OT}

include("DoublyLexicographicallyGreaterThan/dlgt_to_lgt.jl")
const DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThan{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T}, OT}

include("Element/element_to_milp.jl")
const Element2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Element2MILPBridge{T}, OT}

include("ElementVariableArray/elementva_to_milp.jl")
const ElementVariableArray2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ElementVariableArray2MILPBridge{T}, OT}

include("EqualTo_Reify/reif_eqto_to_indic.jl")
const ReificationEqualTo2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ReificationEqualTo2IndicatorBridge{T}, OT}

include("EqualTo_Reify/reif_eqto_to_milp.jl")
const ReificationEqualTo2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ReificationEqualTo2MILPBridge{T}, OT}

include("GreaterThan_Reify/reif_gt_to_indic.jl")
const ReificationGreaterThan2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ReificationGreaterThan2IndicatorBridge{T}, OT}

include("GreaterThan_Reify/reif_gt_to_milp.jl")
const ReificationGreaterThan2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ReificationGreaterThan2MILPBridge{T}, OT}

include("GlobalCardinality/gc_to_count.jl")
const GlobalCardinality2Count{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{GlobalCardinality2CountBridge{T}, OT}

include("GlobalCardinality/gc_to_gcv.jl")
const GlobalCardinality2GlobalCardinalityVariable{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{GlobalCardinality2GlobalCardinalityVariableBridge{T}, OT}

include("GlobalCardinalityVariable/gcv_to_count.jl")
const GlobalCardinalityVariable2Count{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{GlobalCardinalityVariable2CountBridge{T}, OT}

include("IfThenElse/ifthenelse_to_imply.jl")
const IfThenElse2Imply{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{IfThenElse2ImplyBridge{T}, OT}

include("IfThenElse/ifthenelse_to_reif.jl")
const IfThenElse2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{IfThenElse2ReificationBridge{T}, OT}

include("Imply/imply_to_reif.jl")
const Imply2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Imply2ReificationBridge{T}, OT}

include("Increasing/inc_to_lp.jl")
const Increasing2LP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Increasing2LPBridge{T}, OT}

include("Inverse/inverse_to_reif.jl")
const Inverse2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Inverse2ReificationBridge{T}, OT}
    
include("Knapsack/kp_to_milp.jl")
const Knapsack2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Knapsack2MILPBridge{T}, OT}
    
include("Knapsack/kp_to_varcapa.jl")
const Knapsack2VariableCapacityKnapsack{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Knapsack2VariableCapacityKnapsackBridge{T}, OT}

include("Knapsack/vkp_to_kp.jl")
const ValuedKnapsack2Knapsack{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ValuedKnapsack2KnapsackBridge{T}, OT}
    
include("Knapsack/varcapa_to_milp.jl")
const VariableCapacityKnapsack2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VariableCapacityKnapsack2MILPBridge{T}, OT}

include("Knapsack/varcapav_to_varcapa.jl")
const VariableCapacityValuedKnapsack2VariableCapacityKnapsack{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VariableCapacityValuedKnapsack2VariableCapacityKnapsackBridge{T}, OT}

include("LessThan_Reify/reif_lt_to_indic.jl")
const ReificationLessThan2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ReificationLessThan2IndicatorBridge{T}, OT}

include("LessThan_Reify/reif_lt_to_milp.jl")
const ReificationLessThan2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ReificationLessThan2MILPBridge{T}, OT}

include("LexicographicallyGreaterThan/lgt_to_indic.jl")
const LexicographicallyGreaterThan2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{LexicographicallyGreaterThan2IndicatorBridge{T}, OT}

include("LexicographicallyLessThan/llt_to_indic.jl")
const LexicographicallyLessThan2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{LexicographicallyLessThan2IndicatorBridge{T}, OT}

include("Strictly/strictly_dec_to_lp.jl")
const StrictlyDecreasing2LP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{StrictlyDecreasing2LPBridge{T}, OT}

include("Strictly/strictly_dlgt_to_lgt.jl")
const DoublyStrictlyLexicographicallyGreaterThan2LexicographicallyGreaterThan{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T}, OT}

include("Strictly/strictly_dllt_to_llt.jl")
const DoublyStrictlyLexicographicallyLessThan2LexicographicallyLessThan{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyLessThanBridge{T}, OT}

include("Strictly/strictly_inc_to_lp.jl")
const StrictlyIncreasing2LP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{StrictlyIncreasing2LPBridge{T}, OT}

include("Strictly/strictly_lgt_to_indic.jl")
const StrictlyLexicographicallyGreaterThan2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{StrictlyLexicographicallyGreaterThan2IndicatorBridge{T}, OT}

include("Strictly/strictly_llt_to_indic.jl")
const StrictlyLexicographicallyLessThan2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{StrictlyLexicographicallyLessThan2IndicatorBridge{T}, OT}

include("Strictly/strictly_to_lp.jl")
const Strictly2LP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Strictly2LPBridge{T}, OT}

include("MaximumAmong/max_to_milp.jl")
const MaximumAmong2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{MaximumAmong2MILPBridge{T}, OT}

include("MinimumAmong/min_to_milp.jl")
const MinimumAmong2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{MinimumAmong2MILPBridge{T}, OT}

include("NonOverlappingOrthotopes/noov_to_disjunction_milp.jl")
const NonOverlappingOrthotopes2DisjunctionLP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{NonOverlappingOrthotopes2DisjunctionLPBridge{T}, OT}

include("NonOverlappingOrthotopes/noov_to_noovcond.jl")
const NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopes{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T}, OT}

include("Sort/sort_to_milp.jl")
const Sort2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Sort2MILPBridge{T}, OT}

include("Sort/sort_to_perm.jl")
const Sort2SortPermutation{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Sort2SortPermutationBridge{T}, OT}

include("SortPermutation/perm_to_alldiff_indexing.jl")
const SortPermutation2AllDifferent{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{SortPermutation2AllDifferentBridge{T}, OT}

include("SlidingSum/ss_to_lp.jl")
const SlidingSum2LP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{SlidingSum2LPBridge{T}, OT}

include("SymmetricAllDifferent/salldiff_to_alldiff_inverse.jl")
const SymmetricAllDifferent2AllDifferentInverse{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{SymmetricAllDifferent2AllDifferentInverseBridge{T}, OT}

include("ValuePrecedence/vprec_to_reif.jl")
const ValuePrecedence2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ValuePrecedence2ReificationBridge{T}, OT}

include("VectorDomain/vd_to_milp.jl")
const VectorDomain2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VectorDomain2MILPBridge{T}, OT}
