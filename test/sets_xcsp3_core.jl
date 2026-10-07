@testset "XCSP3 structural argument contract" begin
    P, V, E, C = CP.XCSP3Position, CP.XCSP3Positions, CP.XCSP3Expression, CP.XCSP3Condition
    for indices in ([1,2], reshape(1:4,2,2))
        original = copy(indices)
        descriptor = V(indices)
        @test size(descriptor.indices) == size(indices)
        @test descriptor == copy(descriptor)
        indices isa Array && (indices[1] = 9)
        @test descriptor.indices == original
    end
    @test_throws ArgumentError P(0)
    @test_throws ArgumentError V([0,1])
    @test_throws ArgumentError E(:abs,1,2)
    @test_throws ArgumentError E(:eval,1)
    @test_throws ArgumentError CP.XCSP3Core{:unknown}(1)
    @test_throws ArgumentError CP.XCSP3Element(1; list = V([1]), value = 1, condition = C(:eq,1))
    @test_throws DimensionMismatch CP.XCSP3Minimum(1; list = V([1]), condition = C(:eq,P(2)))
    for nested in ([MOI.VariableIndex(1)], (; hidden = [MOI.VariableIndex(1)]), Dict(:bad => MOI.VariableIndex(1)))
        @test_throws ArgumentError CP.XCSP3Intension(1; expression = nested)
    end
    set = CP.XCSP3Intension(1; expression = E(:gt,P(1),2))
    @test MOI.dimension(set) == 1
    @test copy(set) == set
    @test CP.semantic_id(set) == :intension
    @test CP.semantic_variant(set) == :xcsp3
end
