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

    @testset "BinPacking" begin
        include("BinPacking/bp_to_milp.jl")
        include("BinPacking/fixedcapa_to_bp.jl")
        include("BinPacking/fixedcapa_to_varcapa.jl")
        include("BinPacking/varcapa_to_bp.jl")
        include("BinPacking/varcapa_to_milp.jl")
    end

    @testset "DifferentFrom" begin
        include("DifferentFrom/neq_to_pseudolp.jl")
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

    @testset "Strictly" begin
        include("Strictly/strictly_to_lp.jl")
    end
end
