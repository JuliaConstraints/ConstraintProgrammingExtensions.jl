@testset "Constraint bridges" begin
    @testset "BinPacking" begin
        include("BinPacking/bp_to_milp.jl")
        include("BinPacking/fixedcapa_to_bp.jl")
        include("BinPacking/varcapa_to_milp.jl")
    end
end
