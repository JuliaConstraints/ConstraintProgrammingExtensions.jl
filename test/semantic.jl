@testset "Semantic constraint identities" begin
    all_different = MOI.AllDifferent(3)
    except = CP.AllDifferentExceptConstants(3, Set([0]))
    cumulative = CP.CumulativeResource(2)

    @test CP.semantic_id(all_different) == :all_different
    @test CP.semantic_variant(all_different) == :standard
    @test CP.semantic_id(except) == :all_different
    @test CP.semantic_variant(except) == :except_constants
    @test CP.semantic_id(cumulative) == :cumulative
    @test CP.semantic_variant(cumulative) == :fixed_lengths
    @test CP.semantic_version(cumulative) == v"1.0.0"
end
