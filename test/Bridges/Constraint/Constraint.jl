@testset "Constraint bridges" begin
    @testset "AbsoluteValue" begin
        include("AbsoluteValue/abs_to_milp.jl")
    end

    @testset "AllDifferent" begin
        include("AllDifferent/ad_to_neq.jl")
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

    @testset "Count" begin
        include("Count/count_to_reif.jl")
    end

    @testset "Decreasing" begin
        include("Decreasing/dec_to_lp.jl")
    end

    @testset "DifferentFrom" begin
        include("DifferentFrom/neq_to_pseudolp.jl")
    end

    @testset "IndicatorSet{DifferentFrom}" begin
        include("DifferentFrom_Indicator/neq_indicator_to_pseudolp.jl")
    end

    @testset "Reified{MOI.EqualTo}" begin
        include("EqualTo_Reify/reif_eqto_to_indic.jl")
        include("EqualTo_Reify/reif_eqto_to_milp.jl")
    end

    @testset "Increasing" begin
        include("Increasing/inc_to_lp.jl")
    end

    @testset "Knapsack" begin
        include("Knapsack/kp_to_milp.jl")
        include("Knapsack/kp_to_varcapa.jl")
        include("Knapsack/varcapa_to_milp.jl")
        include("Knapsack/vkp_to_kp.jl")
        include("Knapsack/varcapav_to_varcapa.jl")
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

    @testset "Sort" begin
        include("Sort/sort_to_perm.jl")
        include("Sort/sort_to_milp.jl")
    end

    @testset "SortPermutation" begin
        include("SortPermutation/perm_to_alldiff_indexing.jl")
    end

    @testset "Strictly" begin
        include("Strictly/strictly_to_lp.jl")
    end
end
