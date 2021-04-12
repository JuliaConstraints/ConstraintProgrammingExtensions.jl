@testset "FlatZinc" begin
    @test sprint(show, LP.Model()) == "A .LP-file model"
end
