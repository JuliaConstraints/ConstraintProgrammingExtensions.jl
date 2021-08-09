@testset "Constraint bridges" begin
    @testset "AbsoluteValue" begin
        include("AbsoluteValue/abs_to_milp.jl")
    end

    @testset "AllDifferent" begin
        include("AllDifferent/ad_to_neq.jl")
    end

    @testset "AllDifferentExceptConstants" begin
        include("AllDifferentExceptConstants/adec_to_disjunction.jl")
        include("AllDifferentExceptConstants/adec_to_reif.jl")
    end

    @testset "AllEqual" begin
        include("AllEqual/alleq_to_eq.jl")
    end

    @testset "ArgumentMaximumAmong" begin
        include("ArgumentMaximumAmong/argmax_to_milp.jl")
    end

    @testset "ArgumentMinimumAmong" begin
        include("ArgumentMinimumAmong/argmin_to_milp.jl")
    end

    @testset "BinPacking" begin
        include("BinPacking/bp_to_milp.jl")
        include("BinPacking/fixedcapa_to_bp.jl")
        include("BinPacking/fixedcapa_to_varcapa.jl")
        include("BinPacking/varcapa_to_bp.jl")
        include("BinPacking/varcapa_to_milp.jl")
    end

    @testset "Conjunction" begin
        include("Conjunction/conjunction_to_reif.jl")
    end

    @testset "Count" begin
        include("Count/count_to_reif.jl")
    end

    @testset "CountCompare" begin
        include("CountCompare/countcmp_to_count.jl")
    end

    @testset "Decreasing" begin
        include("Decreasing/dec_to_lp.jl")
    end

    @testset "DifferentFrom" begin
        include("DifferentFrom/neq_to_pseudolp.jl")
    end

    @testset "Disjunction" begin
        include("Disjunction/disjunction_to_reif.jl")
    end

    @testset "Domain" begin
        include("Domain/domain_to_milp.jl")
    end

    @testset "DoublyLexicographicallyGreaterThan" begin
        include("DoublyLexicographicallyGreaterThan/dlgt_to_lgt.jl")
    end

    @testset "DoublyLexicographicallyLessThan" begin
        include("DoublyLexicographicallyLessThan/dllt_to_llt.jl")
    end

    @testset "Element" begin
        include("Element/element_to_milp.jl")
    end

    @testset "ElementVariableArray" begin
        include("ElementVariableArray/elementva_to_milp.jl")
    end

    @testset "GlobalCardinality" begin
        include("GlobalCardinality/cgc_to_gc.jl")
        include("GlobalCardinality/cgcv_to_gcv.jl")
        include("GlobalCardinality/gc_to_count.jl")
        include("GlobalCardinality/gc_to_gcv.jl")
        include("GlobalCardinality/gcv_to_count.jl")
    end

    @testset "IfThenElse" begin
        include("IfThenElse/ifthenelse_to_implication.jl")
        include("IfThenElse/ifthenelse_to_reif.jl")
    end

    @testset "Implication" begin
        include("Implication/implication_to_reif.jl")
    end

    @testset "Increasing" begin
        include("Increasing/inc_to_lp.jl")
    end

    @testset "Increasing" begin
        include("Increasing/inc_to_lp.jl")
    end

    @testset "IndicatorSet{DifferentFrom}" begin
        include("DifferentFrom_Indicator/neq_indicator_to_pseudolp.jl")
    end

    @testset "Reification{DifferentFrom}" begin
        include("DifferentFrom_Reify/reif_neq_to_indic.jl")
        include("DifferentFrom_Reify/reif_neq_to_milp.jl")
    end

    @testset "Inverse" begin
        include("Inverse/inverse_to_reif.jl")
    end

    @testset "Knapsack" begin
        include("Knapsack/kp_to_milp.jl")
        include("Knapsack/kp_to_varcapa.jl")
        include("Knapsack/varcapa_to_milp.jl")
        include("Knapsack/vkp_to_kp.jl")
        include("Knapsack/varcapav_to_varcapa.jl")
    end

    @testset "LexicographicallyGreaterThan" begin
        include("LexicographicallyGreaterThan/lgt_to_indic.jl")
    end

    @testset "LexicographicallyLessThan" begin
        include("LexicographicallyLessThan/llt_to_indic.jl")
    end

    @testset "LexicographicallyLessThan" begin
        include("LexicographicallyLessThan/llt_to_indic.jl")
    end

    @testset "MaximumAmong" begin
        include("MaximumAmong/max_to_milp.jl")
    end

    @testset "MinimumAmong" begin
        include("MinimumAmong/min_to_milp.jl")
    end

    @testset "NonOverlappingOrthotopes" begin
        include("NonOverlappingOrthotopes/noov_to_noovcond.jl")
        include("NonOverlappingOrthotopes/noov_to_disjunction_milp.jl")
    end

    @testset "Reification{MOI.EqualTo}" begin
        include("EqualTo_Reify/reif_eqto_to_indic.jl")
        include("EqualTo_Reify/reif_eqto_to_milp.jl")
    end

    @testset "Reification{MOI.GreaterThan}" begin
        include("GreaterThan_Reify/reif_gt_to_indic.jl")
        include("GreaterThan_Reify/reif_gt_to_milp.jl")
    end

    @testset "Reification{MOI.LessThan}" begin
        include("LessThan_Reify/reif_lt_to_indic.jl")
        include("LessThan_Reify/reif_lt_to_milp.jl")
    end

    @testset "SlidingSum" begin
        include("SlidingSum/ss_to_lp.jl")
    end

    @testset "Sort" begin
        include("Sort/sort_to_perm.jl")
        include("Sort/sort_to_milp.jl")
    end

    @testset "SortPermutation" begin
        include("SortPermutation/perm_to_alldiff_indexing.jl")
    end

    @testset "Strictly" begin
        include("Strictly/strictly_dec_to_lp.jl")
        include("Strictly/strictly_dlgt_to_lgt.jl")
        include("Strictly/strictly_dllt_to_llt.jl")
        include("Strictly/strictly_gt_to_strictly_lt.jl")
        include("Strictly/strictly_inc_to_lp.jl")
        include("Strictly/strictly_lgt_to_indic.jl")
        include("Strictly/strictly_llt_to_indic.jl")
        include("Strictly/strictly_lt_to_strictly_gt.jl")
        include("Strictly/strictly_to_lp.jl")
    end

    @testset "SymmetricAllDifferent" begin
        include("SymmetricAllDifferent/salldiff_to_alldiff_inverse.jl")
    end

    @testset "ValuePrecedence" begin
        include("ValuePrecedence/vprec_to_reif.jl")
    end

    @testset "VectorDomain" begin
        include("VectorDomain/vd_to_milp.jl")
    end
end
