@testset "Constraint bridges" begin
    @testset "BinPacking" begin
        include("BinPacking/bp_to_milp.jl")
        include("BinPacking/variablecapacity_to_milp.jl")
    end
end
