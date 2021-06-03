@testset "Constraint bridges" begin
    @testset "BinPacking" begin
        include("BinPacking/bp_to_milp.jl")
        include("BinPacking/fixedcapa_to_bp.jl")
        include("BinPacking/fixedcapa_to_varcapa.jl")
        include("BinPacking/varcapa_to_bp.jl")
        include("BinPacking/varcapa_to_milp.jl")
    end

    @testset "Knapsack" begin
        include("Knapsack/kp_to_milp.jl")
        include("Knapsack/kp_to_varcapa.jl")
        include("Knapsack/varcapa_to_milp.jl")
    end
end
