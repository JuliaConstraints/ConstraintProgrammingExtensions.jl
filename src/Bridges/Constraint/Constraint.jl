include("AbsoluteValue/abs_to_milp.jl")
const AbsoluteValue2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AbsoluteValue2MILPBridge{T}, OT}

include("AllDifferent/ad_to_neq.jl")
const AllDifferent2DifferentFrom{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AllDifferent2DifferentFromBridge{T}, OT}

include("AllDifferentExceptConstants/adec_to_disjunction.jl")
const AllDifferentExceptConstants2ConjunctionDisjunction{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T}, OT}

include("AllDifferentExceptConstants/adec_to_reif.jl")
const AllDifferentExceptConstants2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{AllDifferentExceptConstants2ReificationBridge{T}, OT}

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
    MOIBC.SingleBridgeOptimizer{BinPacking2MILPBridge{CP.NO_CAPACITY_BINPACKING, T}, OT}
const FixedCapacityBinPacking2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{BinPacking2MILPBridge{CP.FIXED_CAPACITY_BINPACKING, T}, OT}
const VariableCapacityBinPacking2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{BinPacking2MILPBridge{CP.VARIABLE_CAPACITY_BINPACKING, T}, OT}

include("BinPacking/fixedcapa_to_bp.jl")
const FixedCapacityBinPacking2BinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{FixedCapacityBinPacking2BinPackingBridge{T}, OT}
    
include("BinPacking/fixedcapa_to_varcapa.jl")
const FixedCapacityBinPacking2VariableCapacityBinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T}, OT}
    
include("BinPacking/varcapa_to_bp.jl")
const VariableCapacityBinPacking2BinPacking{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{VariableCapacityBinPacking2BinPackingBridge{T}, OT}

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

include("DifferentFrom_Indicator/neq_indicator_to_pseudolp.jl")
const Indicator0DifferentFrom2PseudoMILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{IndicatorDifferentFrom2PseudoMILPBridge{T, MOI.ACTIVATE_ON_ZERO}, OT}
const Indicator1DifferentFrom2PseudoMILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{IndicatorDifferentFrom2PseudoMILPBridge{T, MOI.ACTIVATE_ON_ONE}, OT}

include("DifferentFrom_Reify/reif_neq_to_indic.jl")
const ReificationDifferentFrom2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ReificationDifferentFrom2IndicatorBridge{T}, OT}

include("DifferentFrom_Reify/reif_neq_to_milp.jl")
const ReificationDifferentFrom2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ReificationDifferentFrom2MILPBridge{T}, OT}

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

include("GlobalCardinality/cgc_to_gc.jl")
const GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpen{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T}, OT}

include("GlobalCardinality/cgcv_to_gcv.jl")
const GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpen{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T}, OT}

include("GlobalCardinality/gc_to_count.jl")
const GlobalCardinalityFixedOpen2Count{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{GlobalCardinalityFixedOpen2CountBridge{T}, OT}

include("GlobalCardinality/gc_to_gcv.jl")
const GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpen{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T}, OT}

include("GlobalCardinality/gcv_to_count.jl")
const GlobalCardinalityVariableOpen2Count{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{GlobalCardinalityVariableOpen2CountBridge{T}, OT}

include("IfThenElse/ifthenelse_to_implication.jl")
const IfThenElse2Implication{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{IfThenElse2ImplicationBridge{T}, OT}

include("IfThenElse/ifthenelse_to_reif.jl")
const IfThenElse2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{IfThenElse2ReificationBridge{T}, OT}

include("Implication/implication_to_reif.jl")
const Implication2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Implication2ReificationBridge{T}, OT}

include("Increasing/inc_to_lp.jl")
const Increasing2LP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Increasing2LPBridge{T}, OT}

include("Inverse/inverse_to_reif.jl")
const Inverse2Reification{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Inverse2ReificationBridge{T}, OT}
    
include("Knapsack/kp_to_milp.jl")
const Knapsack2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Knapsack2MILPBridge{CP.FIXED_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T}, OT}
const VariableCapacityKnapsack2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Knapsack2MILPBridge{CP.VARIABLE_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T}, OT}
const ValuedKnapsack2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Knapsack2MILPBridge{CP.FIXED_CAPACITY_KNAPSACK, CP.VALUED_KNAPSACK, T}, OT}
const ValuedVariableCapacityKnapsack2MILP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Knapsack2MILPBridge{CP.VARIABLE_CAPACITY_KNAPSACK, CP.VALUED_KNAPSACK, T}, OT}
    
include("Knapsack/kp_to_varcapa.jl")
const Knapsack2VariableCapacityKnapsack{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{Knapsack2VariableCapacityKnapsackBridge{T}, OT}

include("Knapsack/vkp_to_kp.jl")
const ValuedKnapsack2Knapsack{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{ValuedKnapsack2KnapsackBridge{T}, OT}

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

include("Strictly/strictly_gt_to_strictly_lt.jl")
const StrictlyGreaterThan2StrictlyLessThan{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{StrictlyGreaterThan2StrictlyLessThanBridge{T}, OT}

include("Strictly/strictly_inc_to_lp.jl")
const StrictlyIncreasing2LP{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{StrictlyIncreasing2LPBridge{T}, OT}

include("Strictly/strictly_lgt_to_indic.jl")
const StrictlyLexicographicallyGreaterThan2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{StrictlyLexicographicallyGreaterThan2IndicatorBridge{T}, OT}

include("Strictly/strictly_llt_to_indic.jl")
const StrictlyLexicographicallyLessThan2Indicator{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{StrictlyLexicographicallyLessThan2IndicatorBridge{T}, OT}

include("Strictly/strictly_lt_to_strictly_gt.jl")
const StrictlyLessThan2StrictlyGreaterThan{T, OT <: MOI.ModelLike} =
    MOIBC.SingleBridgeOptimizer{StrictlyLessThan2StrictlyGreaterThanBridge{T}, OT}

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

"""
    add_all_set_bridges(bridged_model, ::Type{T}) where {T}

Add all set bridges defined in the `Bridges` submodule to `bridged_model`. 
The coefficient type used is `T`.
"""
function add_all_set_bridges(bridged_model, ::Type{T}) where {T}
    MOIB.add_bridge(bridged_model, AbsoluteValue2MILPBridge{T})
    MOIB.add_bridge(bridged_model, AllDifferent2DifferentFromBridge{T})
    MOIB.add_bridge(bridged_model, AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T})
    MOIB.add_bridge(bridged_model, AllDifferentExceptConstants2ReificationBridge{T})
    MOIB.add_bridge(bridged_model, AllEqual2EqualToBridge{T})
    MOIB.add_bridge(bridged_model, ArgumentMaximumAmong2MILPBridge{T})
    MOIB.add_bridge(bridged_model, ArgumentMinimumAmong2MILPBridge{T})
    MOIB.add_bridge(bridged_model, BinPacking2MILPBridge{T})
    MOIB.add_bridge(bridged_model, FixedCapacityBinPacking2BinPackingBridge{T})
    MOIB.add_bridge(bridged_model, FixedCapacityBinPacking2VariableCapacityBinPackingBridge{T})
    MOIB.add_bridge(bridged_model, VariableCapacityBinPacking2BinPackingBridge{T})
    MOIB.add_bridge(bridged_model, Conjunction2ReificationBridge{T})
    MOIB.add_bridge(bridged_model, Count2ReificationBridge{T, MOI.EqualTo{T}})
    MOIB.add_bridge(bridged_model, Count2ReificationBridge{T, MOI.LessThan{T}})
    MOIB.add_bridge(bridged_model, Count2ReificationBridge{T, MOI.GreaterThan{T}})
    MOIB.add_bridge(bridged_model, Count2ReificationBridge{T, CP.Strictly{MOI.LessThan{T}, T}})
    MOIB.add_bridge(bridged_model, Count2ReificationBridge{T, CP.Strictly{MOI.GreaterThan{T}, T}})
    MOIB.add_bridge(bridged_model, Count2ReificationBridge{T, CP.DifferentFrom{T}})
    MOIB.add_bridge(bridged_model, CountCompare2CountBridge{T})
    MOIB.add_bridge(bridged_model, Decreasing2LPBridge{T})
    MOIB.add_bridge(bridged_model, DifferentFrom2PseudoMILPBridge{T})
    MOIB.add_bridge(bridged_model, IndicatorDifferentFrom2PseudoMILPBridge{T, MOI.ACTIVATE_ON_ZERO})
    MOIB.add_bridge(bridged_model, IndicatorDifferentFrom2PseudoMILPBridge{T, MOI.ACTIVATE_ON_ONE})
    MOIB.add_bridge(bridged_model, ReificationDifferentFrom2IndicatorBridge{T})
    MOIB.add_bridge(bridged_model, ReificationDifferentFrom2MILPBridge{T})
    MOIB.add_bridge(bridged_model, Disjunction2ReificationBridge{T})
    MOIB.add_bridge(bridged_model, Domain2MILPBridge{T})
    MOIB.add_bridge(bridged_model, DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T})
    MOIB.add_bridge(bridged_model, DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T})
    MOIB.add_bridge(bridged_model, Element2MILPBridge{T})
    MOIB.add_bridge(bridged_model, ElementVariableArray2MILPBridge{T})
    MOIB.add_bridge(bridged_model, ReificationEqualTo2IndicatorBridge{T})
    MOIB.add_bridge(bridged_model, ReificationEqualTo2MILPBridge{T})
    MOIB.add_bridge(bridged_model, ReificationGreaterThan2IndicatorBridge{T})
    MOIB.add_bridge(bridged_model, ReificationGreaterThan2MILPBridge{T})
    MOIB.add_bridge(bridged_model, GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T})
    MOIB.add_bridge(bridged_model, GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T})
    MOIB.add_bridge(bridged_model, GlobalCardinalityFixedOpen2CountBridge{T})
    MOIB.add_bridge(bridged_model, GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T})
    MOIB.add_bridge(bridged_model, GlobalCardinalityVariableOpen2CountBridge{T})
    MOIB.add_bridge(bridged_model, IfThenElse2ImplicationBridge{T})
    MOIB.add_bridge(bridged_model, IfThenElse2ReificationBridge{T})
    MOIB.add_bridge(bridged_model, Implication2ReificationBridge{T})
    MOIB.add_bridge(bridged_model, Increasing2LPBridge{T})
    MOIB.add_bridge(bridged_model, Inverse2ReificationBridge{T})
    MOIB.add_bridge(bridged_model, Knapsack2MILPBridge{T})
    MOIB.add_bridge(bridged_model, Knapsack2VariableCapacityKnapsackBridge{T})
    MOIB.add_bridge(bridged_model, ValuedKnapsack2KnapsackBridge{T})
    MOIB.add_bridge(bridged_model, VariableCapacityValuedKnapsack2VariableCapacityKnapsackBridge{T})
    MOIB.add_bridge(bridged_model, ReificationLessThan2IndicatorBridge{T})
    MOIB.add_bridge(bridged_model, ReificationLessThan2MILPBridge{T})
    MOIB.add_bridge(bridged_model, LexicographicallyGreaterThan2IndicatorBridge{T})
    MOIB.add_bridge(bridged_model, LexicographicallyLessThan2IndicatorBridge{T})
    MOIB.add_bridge(bridged_model, StrictlyDecreasing2LPBridge{T})
    MOIB.add_bridge(bridged_model, DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T})
    MOIB.add_bridge(bridged_model, DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyLessThanBridge{T})
    MOIB.add_bridge(bridged_model, StrictlyIncreasing2LPBridge{T})
    MOIB.add_bridge(bridged_model, StrictlyLexicographicallyGreaterThan2IndicatorBridge{T})
    MOIB.add_bridge(bridged_model, StrictlyLexicographicallyLessThan2IndicatorBridge{T})
    MOIB.add_bridge(bridged_model, Strictly2LPBridge{T})
    MOIB.add_bridge(bridged_model, MaximumAmong2MILPBridge{T})
    MOIB.add_bridge(bridged_model, MinimumAmong2MILPBridge{T})
    MOIB.add_bridge(bridged_model, NonOverlappingOrthotopes2DisjunctionLPBridge{T})
    MOIB.add_bridge(bridged_model, NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T})
    MOIB.add_bridge(bridged_model, Sort2MILPBridge{T})
    MOIB.add_bridge(bridged_model, Sort2SortPermutationBridge{T})
    MOIB.add_bridge(bridged_model, SortPermutation2AllDifferentBridge{T})
    MOIB.add_bridge(bridged_model, SlidingSum2LPBridge{T})
    MOIB.add_bridge(bridged_model, SymmetricAllDifferent2AllDifferentInverseBridge{T})
    MOIB.add_bridge(bridged_model, ValuePrecedence2ReificationBridge{T})
    MOIB.add_bridge(bridged_model, VectorDomain2MILPBridge{T})
end
