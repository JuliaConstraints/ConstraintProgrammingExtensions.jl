@testset "Sets" begin
    # No argument.
    @testset "$(S)" for S in [
        CP.AbsoluteValue,
    ]
        @test isbitstype(S)
        
        @test S() == S()

        s = S()
        @test typeof(copy(s)) <: S
        @test copy(s) === s # Same object.
        
        @test MOI.dimension(S()) == 2
    end

    # Just a dimension.
    @testset "$(S)" for S in [
        CP.AllEqual,
        CP.AllDifferent,
        CP.Membership,
        CP.ElementVariableArray,
        CP.CountDistinct,
        CP.Inverse,
        CP.Contiguity,
        CP.Circuit,
        CP.CircuitPath,
        CP.CumulativeResource,
        CP.CumulativeResourceWithDeadline,
        CP.LexicographicallyLessThan,
        CP.LexicographicallyGreaterThan,
        CP.Sort,
        CP.SortPermutation,
        CP.MinimumAmong,
        CP.MaximumAmong,
        CP.ArgumentMinimumAmong,
        CP.ArgumentMaximumAmong,
        CP.Increasing,
        CP.Decreasing,
    ]
        @test isbitstype(S)

        @test S(2) == S(2)
        @test S(2) != S(3)
        @test S(3) != S(2)

        s = S(2)
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        if S in [
            CP.AllEqual,
            CP.AllDifferent,
            CP.Membership,
            CP.Contiguity,
            CP.Circuit,
            CP.Increasing,
            CP.Decreasing,
        ]
            @test MOI.dimension(S(2)) == 2
            @test MOI.dimension(S(3)) == 3
        elseif S in [
            CP.CountDistinct,
            CP.MinimumAmong,
            CP.MaximumAmong,
            CP.ArgumentMinimumAmong,
            CP.ArgumentMaximumAmong,
        ]
            @test MOI.dimension(S(2)) == 2 + 1
            @test MOI.dimension(S(3)) == 3 + 1
        elseif S == CP.ElementVariableArray
            @test MOI.dimension(S(2)) == 2 + 2
            @test MOI.dimension(S(3)) == 3 + 2
        elseif S in [
            CP.Inverse,
            CP.CircuitPath,
            CP.LexicographicallyLessThan,
            CP.LexicographicallyGreaterThan,
            CP.Sort,
        ]
            @test MOI.dimension(S(2)) == 2 * 2
            @test MOI.dimension(S(3)) == 3 * 2
        elseif S == CP.SortPermutation
            @test MOI.dimension(S(2)) == 2 * 3
            @test MOI.dimension(S(3)) == 3 * 3
        elseif S == CP.CumulativeResource
            @test MOI.dimension(S(2)) == 2 * 3 + 1
            @test MOI.dimension(S(3)) == 3 * 3 + 1
        elseif S == CP.CumulativeResourceWithDeadline
            @test MOI.dimension(S(2)) == 2 * 4 + 1
            @test MOI.dimension(S(3)) == 3 * 4 + 1
        else
            error("$(S) not implemented")
        end
    end

    # Two arguments: first a dimension, then a templated constant.
    @testset "$(S)" for S in [
        CP.AllDifferentExceptConstant,
        CP.Count,
        CP.MinimumDistance,
        CP.MaximumDistance,
    ]
        @test isbitstype(S{Int})

        @test S(2, 0) == S(2, 0)
        @test S(2, 0) != S(2, 1)
        @test S(2, 0) != S(3, 0)
        @test S(3, 0) != S(2, 0)

        s = S(2, 0)
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        if S in [
            CP.AllDifferentExceptConstant,
            CP.MaximumDistance,
            CP.MinimumDistance,
        ]
            @test MOI.dimension(S(2, 0)) == 2
            @test MOI.dimension(S(3, 4)) == 3
        elseif S == CP.Count
            @test MOI.dimension(S(2, 0)) == 2 + 1
            @test MOI.dimension(S(3, 4)) == 3 + 1
        else
            error("$(S) not implemented")
        end
    end

    @testset "CountCompare" begin
        @test isbitstype(CP.CountCompare)

        @test CP.CountCompare(2) == CP.CountCompare(2)
        @test CP.CountCompare(2) != CP.CountCompare(3)
        @test CP.CountCompare(3) != CP.CountCompare(2)

        s = CP.CountCompare(2)
        @test typeof(copy(s)) <: CP.CountCompare
        @test copy(s) == s

        @test MOI.dimension(CP.CountCompare(2)) == 2 * 2 + 1
        @test MOI.dimension(CP.CountCompare(3)) == 3 * 2 + 1
    end

    @testset "Element" begin
        set1 = [1, 2, 3]
        set2 = [1, 2, 3, 4]
        @test CP.Element(set1) == CP.Element(set1)
        @test CP.Element(set1) != CP.Element(set2)
        @test CP.Element(set2) != CP.Element(set1)

        s = CP.Element(set1)
        @test typeof(copy(s)) <: CP.Element
        @test copy(s) == s

        @test MOI.dimension(CP.Element(set1)) == 2
        @test MOI.dimension(CP.Element(set2)) == 2
    end

    @testset "$(S)" for S in [CP.Domain, CP.AntiDomain]
        set1 = Set([1, 2, 3])
        set2 = Set([1, 2, 3, 4])
        @test S(set1) == S(set1)
        @test S(set1) != S(set2)
        @test S(set2) != S(set1)

        s = S(set1)
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        @test MOI.dimension(S(set1)) == 1
        @test MOI.dimension(S(set2)) == 1
    end

    @testset "Strictly{$(Ssub)}" for Ssub in [MOI.LessThan, MOI.GreaterThan]
        @test CP.Strictly(Ssub(1)) == CP.Strictly(Ssub(1))
        @test CP.Strictly(Ssub(1)) != CP.Strictly(Ssub(2))
        @test CP.Strictly(Ssub(2)) == CP.Strictly(Ssub(2))
        @test CP.Strictly(Ssub(2)) != CP.Strictly(Ssub(1))

        s = CP.Strictly(Ssub(1))
        @test typeof(copy(s)) <: CP.Strictly{Ssub{Int}}
        @test copy(s) == s

        @test MOI.dimension(CP.Strictly(Ssub(3))) == 1
        @test MOI.dimension(CP.Strictly(Ssub(1))) == 1
        @test MOI.dimension(CP.Strictly(Ssub(3))) == MOI.dimension(Ssub(3))

        @test MOI.constant(CP.Strictly(Ssub(3))) == 3
        @test MOIU.shift_constant(CP.Strictly(Ssub(3)), 1) ==
              CP.Strictly(Ssub(4))
    end

    @testset "Strictly{$(Ssub)}" for Ssub in [
        CP.LexicographicallyLessThan,
        CP.LexicographicallyGreaterThan,
        CP.Increasing,
        CP.Decreasing,
    ]
        @test CP.Strictly(Ssub(1)) == CP.Strictly(Ssub(1))
        @test CP.Strictly(Ssub(1)) != CP.Strictly(Ssub(2))
        @test CP.Strictly(Ssub(2)) == CP.Strictly(Ssub(2))
        @test CP.Strictly(Ssub(2)) != CP.Strictly(Ssub(1))

        s = CP.Strictly(Ssub(1))
        @test typeof(copy(s)) <: CP.Strictly{Ssub}
        @test copy(s) == s

        if Ssub in
           [CP.LexicographicallyLessThan, CP.LexicographicallyGreaterThan]
            @test MOI.dimension(CP.Strictly(Ssub(3))) == 3 * 2
            @test MOI.dimension(CP.Strictly(Ssub(1))) == 1 * 2
        elseif Ssub in [CP.Increasing, CP.Decreasing]
            @test MOI.dimension(CP.Strictly(Ssub(3))) == 3
            @test MOI.dimension(CP.Strictly(Ssub(1))) == 1
        else
            error("$(S) not implemented")
        end

        if Ssub in [MOI.LessThan, MOI.GreaterThan]
            @test MOI.constant(CP.Strictly(Ssub(3))) == 3
            @test MOIU.shift_constant(CP.Strictly(Ssub(3)), 1) ==
                  CP.Strictly(Ssub(4))
        end
    end

    @testset "DifferentFrom" begin
        @test isbitstype(CP.DifferentFrom{Float64})

        @test CP.DifferentFrom(1) == CP.DifferentFrom(1)
        @test CP.DifferentFrom(1) != CP.DifferentFrom(2)
        @test CP.DifferentFrom(2) == CP.DifferentFrom(2)
        @test CP.DifferentFrom(2) != CP.DifferentFrom(1)

        s = CP.DifferentFrom(1)
        @test typeof(copy(s)) <: CP.DifferentFrom
        @test copy(s) == s

        @test MOI.constant(CP.DifferentFrom(3)) == 3
        @test MOI.dimension(CP.DifferentFrom(3)) == 1
        @test MOIU.shift_constant(CP.DifferentFrom(3), 1) == CP.DifferentFrom(4)
    end

    @testset "BinPacking family" begin
        @testset "BinPacking" begin
            @test_throws AssertionError CP.BinPacking(1, 2, [1, 2, 3])

            @test CP.BinPacking(1, 2, [1, 2]) == CP.BinPacking(1, 2, [1, 2])
            @test CP.BinPacking(2, 2, [1, 2]) != CP.BinPacking(1, 2, [1, 2])
            @test CP.BinPacking(1, 3, [1, 2, 3]) != CP.BinPacking(1, 2, [1, 2])

            s = CP.BinPacking(1, 2, [1, 2])
            @test typeof(copy(s)) <: CP.BinPacking
            @test copy(s) == s

            @test MOI.dimension(CP.BinPacking(1, 2, [1, 2])) == 3
            
            @test_throws AssertionError CP.BinPacking(1, 2, [-1, 2])
            @test_throws AssertionError CP.BinPacking(0, 2, [1, 2])
            @test_throws AssertionError CP.BinPacking(1, 0, [1, 2])
        end

        @testset "FixedCapacityBinPacking" begin
            @test_throws AssertionError CP.FixedCapacityBinPacking(
                1,
                2,
                [1, 2, 3],
                [4],
            )
            @test_throws AssertionError CP.FixedCapacityBinPacking(
                1,
                2,
                [1, 2],
                [3, 4],
            )
            @test_throws AssertionError CP.FixedCapacityBinPacking(
                1,
                2,
                [1, 2, 3],
                [4, 5],
            )

            @test CP.FixedCapacityBinPacking(1, 2, [1, 2], [4]) ==
                CP.FixedCapacityBinPacking(1, 2, [1, 2], [4])
            @test CP.FixedCapacityBinPacking(2, 2, [1, 2], [4, 5]) !=
                CP.FixedCapacityBinPacking(1, 2, [1, 2], [4])
            @test CP.FixedCapacityBinPacking(1, 3, [1, 2, 3], [4]) !=
                CP.FixedCapacityBinPacking(1, 2, [1, 2], [4])

            s = CP.FixedCapacityBinPacking(1, 2, [1, 2], [4])
            @test typeof(copy(s)) <: CP.FixedCapacityBinPacking
            @test copy(s) == s

            @test MOI.dimension(CP.FixedCapacityBinPacking(1, 2, [1, 2], [4])) == 3

            @test_throws AssertionError CP.FixedCapacityBinPacking(1, 2, [-1, 2], [4])
            @test_throws AssertionError CP.FixedCapacityBinPacking(1, 2, [1, 2], [-4])
            @test_throws AssertionError CP.FixedCapacityBinPacking(0, 2, [1, 2], [4])
            @test_throws AssertionError CP.FixedCapacityBinPacking(1, 0, [1, 2], [4])
        end

        @testset "VariableCapacityBinPacking" begin
            @test_throws AssertionError CP.VariableCapacityBinPacking(
                1,
                2,
                [1, 2, 3],
            )

            @test CP.VariableCapacityBinPacking(1, 2, [1, 2]) ==
                CP.VariableCapacityBinPacking(1, 2, [1, 2])
            @test CP.VariableCapacityBinPacking(2, 2, [1, 2]) !=
                CP.VariableCapacityBinPacking(1, 2, [1, 2])
            @test CP.VariableCapacityBinPacking(1, 3, [1, 2, 3]) !=
                CP.VariableCapacityBinPacking(1, 2, [1, 2])

            s = CP.VariableCapacityBinPacking(1, 2, [1, 2])
            @test typeof(copy(s)) <: CP.VariableCapacityBinPacking
            @test copy(s) == s

            @test MOI.dimension(CP.VariableCapacityBinPacking(1, 2, [1, 2])) == 4

            @test_throws AssertionError CP.VariableCapacityBinPacking(1, 2, [-1, 2])
            @test_throws AssertionError CP.VariableCapacityBinPacking(0, 2, [1, 2])
            @test_throws AssertionError CP.VariableCapacityBinPacking(1, 0, [1, 2])
        end
    end

    @testset "Knapsack family" begin
        @testset "Knapsack" begin
            @test CP.Knapsack([1, 2, 3], 3) == CP.Knapsack([1, 2, 3], 3)
            @test CP.Knapsack([1, 2, 3], 3) != CP.Knapsack([1, 2, 3], 4)
            @test CP.Knapsack([1, 2, 3], 4) != CP.Knapsack([1, 2, 3], 3)

            s = CP.Knapsack([1, 2, 3], 3)
            @test typeof(copy(s)) <: CP.Knapsack
            @test copy(s) == s

            @test MOI.dimension(CP.Knapsack([1, 2, 3], 3)) == 3

            @test_throws AssertionError CP.Knapsack([-1, 2, 3], 3)
            @test_throws AssertionError CP.Knapsack([1, 2, 3], -3)
        end

        @testset "VariableCapacityKnapsack" begin
            @test CP.VariableCapacityKnapsack([1, 2, 3]) ==
                CP.VariableCapacityKnapsack([1, 2, 3])

            s = CP.VariableCapacityKnapsack([1, 2, 3])
            @test typeof(copy(s)) <: CP.VariableCapacityKnapsack
            @test copy(s) == s

            @test MOI.dimension(CP.VariableCapacityKnapsack([1, 2, 3])) == 3 + 1

            @test_throws AssertionError CP.VariableCapacityKnapsack([-1, 2, 3])
        end

        @testset "ValuedKnapsack" begin
            @test CP.ValuedKnapsack([1, 2, 3], [1, 2, 3], 3) == CP.ValuedKnapsack([1, 2, 3], [1, 2, 3], 3)
            @test CP.ValuedKnapsack([1, 2, 3], [1, 2, 3], 3) != CP.ValuedKnapsack([1, 2, 3], [1, 2, 3], 4)
            @test CP.ValuedKnapsack([1, 2, 3], [1, 2, 3], 4) != CP.ValuedKnapsack([1, 2, 3], [1, 2, 3], 3)

            s = CP.ValuedKnapsack([1, 2, 3], [1, 2, 3], 3)
            @test typeof(copy(s)) <: CP.ValuedKnapsack
            @test copy(s) == s

            @test MOI.dimension(CP.ValuedKnapsack([1, 2, 3], [1, 2, 3], 3)) == 3 + 1

            @test_throws AssertionError CP.ValuedKnapsack([-1, 2, 3], [1, 2, 3], 3)
            @test_throws AssertionError CP.ValuedKnapsack([1, 2, 3], [-1, 2, 3], 3)
            @test_throws AssertionError CP.ValuedKnapsack([1, 2, 3], [1, 2, 3], -3)
        end

        @testset "VariableCapacityValuedKnapsack" begin
            @test CP.VariableCapacityValuedKnapsack([1, 2, 3], [1, 2, 3]) ==
                CP.VariableCapacityValuedKnapsack([1, 2, 3], [1, 2, 3])

            s = CP.VariableCapacityValuedKnapsack([1, 2, 3], [1, 2, 3])
            @test typeof(copy(s)) <: CP.VariableCapacityValuedKnapsack
            @test copy(s) == s

            @test MOI.dimension(CP.VariableCapacityValuedKnapsack([1, 2, 3], [1, 2, 3])) == 3 + 2

            @test_throws AssertionError CP.VariableCapacityValuedKnapsack([-1, 2, 3], [1, 2, 3])
            @test_throws AssertionError CP.VariableCapacityValuedKnapsack([1, 2, 3], [-1, 2, 3])
        end
    end

    @testset "$(S)" for S in [CP.WeightedCircuit, CP.WeightedCircuitPath]
        @test S(3, [1 2 3; 4 5 6; 7 8 9]) == S(3, [1 2 3; 4 5 6; 7 8 9])
        @test S(3, [1 2 3; 4 5 6; 7 8 9]) != S(2, [1 2; 3 4])
        @test S(2, [1 2; 3 4]) != S(3, [1 2 3; 4 5 6; 7 8 9])

        s = S(3, [1 2 3; 4 5 6; 7 8 9])
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        if S == CP.WeightedCircuit
            @test MOI.dimension(S(3, [1 2 3; 4 5 6; 7 8 9])) == 3 + 1
        elseif S == CP.WeightedCircuitPath
            @test MOI.dimension(S(3, [1 2 3; 4 5 6; 7 8 9])) == 3 * 2 + 1
        else
            error("$(S) not implemented")
        end
    end

    @testset "$(S)" for S in [CP.Reified, CP.Negation]
        @test S(MOI.EqualTo(0.0)) == S(MOI.EqualTo(0.0))
        @test S(MOI.EqualTo(0.0)) != S(MOI.EqualTo(1.0))
        @test S(MOI.EqualTo(1.0)) != S(MOI.EqualTo(0.0))
        @test S(MOI.GreaterThan(0.0)) != S(MOI.EqualTo(1.0))
        @test S(MOI.EqualTo(1.0)) != S(MOI.GreaterThan(0.0))

        s = S(MOI.EqualTo(0.0))
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        if S == CP.Reified
            @test MOI.dimension(S(MOI.EqualTo(0.0))) ==
                  1 + MOI.dimension(MOI.EqualTo(0.0))
            @test MOI.dimension(S(MOI.GreaterThan(0.0))) ==
                  1 + MOI.dimension(MOI.GreaterThan(0.0))
        elseif S == CP.Negation
            @test MOI.dimension(S(MOI.EqualTo(0.0))) ==
                  MOI.dimension(MOI.EqualTo(0.0))
            @test MOI.dimension(S(MOI.GreaterThan(0.0))) ==
                  MOI.dimension(MOI.GreaterThan(0.0))
        else
            error("$(S) not implemented")
        end
    end

    @testset "$(S)" for S in [CP.Equivalence, CP.EquivalenceNot, CP.Imply]
        @test S(MOI.EqualTo(0.0), MOI.EqualTo(0.0)) ==
              S(MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test S(MOI.EqualTo(0.0), MOI.EqualTo(0.0)) !=
              S(MOI.EqualTo(1.0), MOI.EqualTo(0.0))
        @test S(MOI.EqualTo(1.0), MOI.EqualTo(0.0)) !=
              S(MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test S(MOI.GreaterThan(0.0), MOI.EqualTo(0.0)) !=
              S(MOI.EqualTo(1.0), MOI.EqualTo(0.0))
        @test S(MOI.EqualTo(1.0), MOI.EqualTo(0.0)) !=
              S(MOI.GreaterThan(0.0), MOI.EqualTo(0.0))

        s = S(MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        @test MOI.dimension(S(MOI.EqualTo(0.0), MOI.EqualTo(0.0))) ==
              2 * MOI.dimension(MOI.EqualTo(0.0))
        @test MOI.dimension(S(MOI.GreaterThan(0.0), MOI.EqualTo(0.0))) ==
              2 * MOI.dimension(MOI.GreaterThan(0.0))
    end

    @testset "$(S)" for S in [CP.IfThenElse]
        @test S(MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) ==
              S(MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test S(MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) !=
              S(MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test S(MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) !=
              S(MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test S(MOI.GreaterThan(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) !=
              S(MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test S(MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) !=
              S(MOI.GreaterThan(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))

        s = S(MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        @test MOI.dimension(
            S(MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)),
        ) == 3 * MOI.dimension(MOI.EqualTo(0.0))
        @test MOI.dimension(
            S(MOI.GreaterThan(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)),
        ) == 3 * MOI.dimension(MOI.GreaterThan(0.0))
    end

    @testset "$(S)" for S in [CP.Conjunction, CP.Disjunction]
        @test S((MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))) ==
              S((MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)))
        @test S((MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))) !=
              S((MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)))
        @test S((MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))) !=
              S((MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)))
        @test S((MOI.GreaterThan(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))) !=
              S((MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)))
        @test S((MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))) !=
              S((MOI.GreaterThan(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)))

        s = S((MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)))
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        @test MOI.dimension(
            S((MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))),
        ) == 3 * MOI.dimension(MOI.EqualTo(0.0))
        @test MOI.dimension(
            S((MOI.GreaterThan(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))),
        ) == 3 * MOI.dimension(MOI.GreaterThan(0.0))
    end

    @testset "$(S)" for S in [CP.True, CP.False]
        @test isbitstype(S)

        @test S() == S()

        s = S()
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        @test MOI.dimension(S()) == 0
    end
end
