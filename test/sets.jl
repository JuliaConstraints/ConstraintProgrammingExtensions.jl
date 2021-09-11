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
        CP.SymmetricAllDifferent,
        CP.Membership,
        CP.ElementVariableArray,
        CP.CountDistinct,
        CP.Inverse,
        CP.Contiguity,
        CP.Circuit,
        CP.CircuitPath,
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
            CP.SymmetricAllDifferent,
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
        else
            error("$(S) not implemented")
        end
    end

    # Two arguments: first a dimension, then a templated constant.
    @testset "$(S)" for S in [
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

    # Two arguments: two dimensions.
    @testset "$(S)" for S in [
        CP.LexicographicallyLessThan,
        CP.LexicographicallyGreaterThan,
        CP.DoublyLexicographicallyLessThan,
        CP.DoublyLexicographicallyGreaterThan,
    ]
        @test isbitstype(S)

        @test S(2, 2) == S(2, 2)
        @test S(2, 2) != S(2, 1)
        @test S(2, 2) != S(3, 2)
        @test S(3, 2) != S(2, 2)

        s = S(2, 2)
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        if S == CP.LexicographicallyLessThan || S == CP.LexicographicallyGreaterThan || S == CP.DoublyLexicographicallyLessThan || S == CP.DoublyLexicographicallyGreaterThan
            @test MOI.dimension(S(2, 2)) == 2 * 2
            @test MOI.dimension(S(3, 4)) == 3 * 4
        else
            error("$(S) not implemented")
        end
    end

    @testset "AllDifferentExceptConstants" begin
        # Convenience constructor for one value.
        @test CP.AllDifferentExceptConstant(2, 0) == CP.AllDifferentExceptConstant(2, 0)
        @test CP.AllDifferentExceptConstant(2, 0) != CP.AllDifferentExceptConstant(2, 1)
        @test CP.AllDifferentExceptConstant(2, 0) != CP.AllDifferentExceptConstant(3, 0)
        @test CP.AllDifferentExceptConstant(3, 0) != CP.AllDifferentExceptConstant(2, 0)

        s = CP.AllDifferentExceptConstant(2, 0)
        @test typeof(copy(s)) <: CP.AllDifferentExceptConstants
        @test copy(s) == s
        
        @test MOI.dimension(CP.AllDifferentExceptConstant(2, 0)) == 2
        @test MOI.dimension(CP.AllDifferentExceptConstant(3, 4)) == 3

        # Usual constructor.
        @test CP.AllDifferentExceptConstants(2, Set([0, 1])) == CP.AllDifferentExceptConstants(2, Set([0, 1]))
        @test CP.AllDifferentExceptConstants(2, Set([0, 1])) != CP.AllDifferentExceptConstants(2, Set([2, 3]))
        @test CP.AllDifferentExceptConstants(2, Set([0, 1])) != CP.AllDifferentExceptConstants(3, Set([0, 1]))
        @test CP.AllDifferentExceptConstants(3, Set([0, 1])) != CP.AllDifferentExceptConstants(2, Set([0, 1]))

        s = CP.AllDifferentExceptConstants(2, Set([0, 1]))
        @test typeof(copy(s)) <: CP.AllDifferentExceptConstants
        @test copy(s) == s
        
        @test MOI.dimension(CP.AllDifferentExceptConstants(2, Set([0, 1]))) == 2
        @test MOI.dimension(CP.AllDifferentExceptConstants(3, Set([2, 3]))) == 3
    end

    @testset "Count{…}" begin
        @test isbitstype(CP.Count{MOI.EqualTo{Int}})

        # Default constructor: MOI.EqualTo.
        @test CP.Count(2, 0) == CP.Count(2, 0)
        @test CP.Count(2, 0) != CP.Count(2, 1)
        @test CP.Count(2, 0) != CP.Count(3, 0)
        @test CP.Count(3, 0) != CP.Count(2, 0)

        s = CP.Count(2, 0)
        @test typeof(copy(s)) <: CP.Count
        @test copy(s) == s
        
        @test MOI.dimension(CP.Count(2, 0)) == 2 + 1
        @test MOI.dimension(CP.Count(3, 4)) == 3 + 1

        # Directly give a MOI.EqualTo object.
        @test CP.Count(2, MOI.EqualTo(0)) == CP.Count(2, MOI.EqualTo(0))
        @test CP.Count(2, MOI.EqualTo(0)) != CP.Count(2, MOI.EqualTo(1))
        @test CP.Count(2, MOI.EqualTo(0)) != CP.Count(3, MOI.EqualTo(0))
        @test CP.Count(3, MOI.EqualTo(0)) != CP.Count(2, MOI.EqualTo(0))

        s = CP.Count(2, MOI.EqualTo(0))
        @test typeof(copy(s)) <: CP.Count
        @test copy(s) == s
        
        @test MOI.dimension(CP.Count(2, MOI.EqualTo(0))) == 2 + 1
        @test MOI.dimension(CP.Count(3, MOI.EqualTo(4))) == 3 + 1
    
        # Other sets.
        @test CP.Count(2, CP.DifferentFrom(0)) == CP.Count(2, CP.DifferentFrom(0))
        @test CP.Count(2, CP.DifferentFrom(0)) != CP.Count(2, CP.DifferentFrom(1))
        @test CP.Count(2, CP.DifferentFrom(0)) != CP.Count(3, CP.DifferentFrom(0))
        @test CP.Count(3, CP.DifferentFrom(0)) != CP.Count(2, CP.DifferentFrom(0))

        s = CP.Count(2, CP.DifferentFrom(0))
        @test typeof(copy(s)) <: CP.Count
        @test copy(s) == s
        
        @test MOI.dimension(CP.Count(2, CP.DifferentFrom(0))) == 2 + 1
        @test MOI.dimension(CP.Count(3, CP.DifferentFrom(4))) == 3 + 1
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

    @testset "SlidingSum" begin
        @test CP.SlidingSum(1, 2, 3, 4) == CP.SlidingSum(1, 2, 3, 4)
        @test CP.SlidingSum(1, 2, 3, 4) != CP.SlidingSum(0, 2, 3, 4)
        @test CP.SlidingSum(1, 2, 3, 4) != CP.SlidingSum(1, 4, 2, 4)
        @test CP.SlidingSum(1, 2, 3, 4) != CP.SlidingSum(1, 2, 3, 5)

        s = CP.SlidingSum(1, 2, 3, 4)
        @test typeof(copy(s)) <: CP.SlidingSum
        @test copy(s) == s

        @test MOI.dimension(CP.SlidingSum(1, 2, 3, 4)) == 4
        @test MOI.dimension(CP.SlidingSum(1, 2, 3, 40)) == 40
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
        @test S(Set([0, 1])) == S(Set([0, 1]))
        @test S(Set([0, 1])) != S(Set([0, 2]))

        s = S(set1)
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        @test MOI.dimension(S(set1)) == 1
        @test MOI.dimension(S(set2)) == 1
    end

    @testset "$(S)" for S in [CP.VectorDomain, CP.VectorAntiDomain]
        set1 = Set([[1, 2, 3], [2, 3, 4]])
        set2 = Set([[1, 2, 3], [3, 4, 5]])
        @test S(3, set1) == S(3, set1)
        @test S(3, set1) != S(3, set2)
        @test S(3, set2) != S(3, set1)

        s = S(3, set1)
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        @test MOI.dimension(S(3, set1)) == 3
        @test MOI.dimension(S(3, set2)) == 3
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

    @testset "Strictly{$(Ssub), $(T)}, one argument" for Ssub in [
        CP.LexicographicallyLessThan,
        CP.LexicographicallyGreaterThan,
        CP.Increasing,
        CP.Decreasing,
    ], T in [Int, Float64]
        @test CP.Strictly{Ssub, T}(Ssub(1)) == CP.Strictly{Ssub, T}(Ssub(1))
        @test CP.Strictly{Ssub, T}(Ssub(1)) != CP.Strictly{Ssub, T}(Ssub(2))
        @test CP.Strictly{Ssub, T}(Ssub(2)) == CP.Strictly{Ssub, T}(Ssub(2))
        @test CP.Strictly{Ssub, T}(Ssub(2)) != CP.Strictly{Ssub, T}(Ssub(1))

        s = CP.Strictly{Ssub, T}(Ssub(1))
        @test typeof(copy(s)) <: CP.Strictly{Ssub, T}
        @test copy(s) == s

        if Ssub in
           [CP.LexicographicallyLessThan, CP.LexicographicallyGreaterThan]
            @test MOI.dimension(CP.Strictly(Ssub(3))) == 3 * 2
            @test MOI.dimension(CP.Strictly(Ssub(1))) == 1 * 2
        elseif Ssub in [CP.Increasing, CP.Decreasing]
            @test MOI.dimension(CP.Strictly(Ssub(3))) == 3
            @test MOI.dimension(CP.Strictly(Ssub(1))) == 1
        else
            error("$(Ssub) not implemented")
        end

        if Ssub in [MOI.LessThan, MOI.GreaterThan]
            @test MOI.constant(CP.Strictly(Ssub(3))) == 3
            @test MOIU.shift_constant(CP.Strictly(Ssub(3)), 1) ==
                  CP.Strictly(Ssub(4))
        end
    end

    @testset "Strictly{$(Ssub), $(T)}, two arguments" for Ssub in [
        CP.LexicographicallyLessThan,
        CP.LexicographicallyGreaterThan,
        CP.DoublyLexicographicallyLessThan,
        CP.DoublyLexicographicallyGreaterThan,
    ], T in [Int, Float64]
        @test CP.Strictly{Ssub, T}(Ssub(1, 4)) == CP.Strictly{Ssub, T}(Ssub(1, 4))
        @test CP.Strictly{Ssub, T}(Ssub(1, 4)) != CP.Strictly{Ssub, T}(Ssub(2, 4))
        @test CP.Strictly{Ssub, T}(Ssub(2, 4)) == CP.Strictly{Ssub, T}(Ssub(2, 4))
        @test CP.Strictly{Ssub, T}(Ssub(2, 4)) != CP.Strictly{Ssub, T}(Ssub(1, 4))

        s = CP.Strictly{Ssub, T}(Ssub(1, 4))
        @test typeof(copy(s)) <: CP.Strictly{Ssub, T}
        @test copy(s) == s

        if Ssub in
           [CP.LexicographicallyLessThan, CP.LexicographicallyGreaterThan,
           CP.DoublyLexicographicallyLessThan,
           CP.DoublyLexicographicallyGreaterThan,]
            @test MOI.dimension(CP.Strictly(Ssub(3, 4))) == 3 * 4
            @test MOI.dimension(CP.Strictly(Ssub(1, 4))) == 1 * 4
        else
            error("$(Ssub) not implemented")
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

    @testset "$(S)" for S in [CP.Reification, CP.Negation]
        @test S(MOI.EqualTo(0.0)) == S(MOI.EqualTo(0.0))
        @test S(MOI.EqualTo(0.0)) != S(MOI.EqualTo(1.0))
        @test S(MOI.EqualTo(1.0)) != S(MOI.EqualTo(0.0))
        @test S(MOI.GreaterThan(0.0)) != S(MOI.EqualTo(1.0))
        @test S(MOI.EqualTo(1.0)) != S(MOI.GreaterThan(0.0))

        s = S(MOI.EqualTo(0.0))
        @test typeof(copy(s)) <: S
        @test copy(s) == s

        if S == CP.Reification
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

    @testset "$(S)" for S in [CP.Equivalence, CP.EquivalenceNot, CP.Implication]
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

    @testset "$(S)" for S in [CP.Conjunction, CP.Disjunction, CP.ExclusiveDisjunction]
        # Ensure that tuples can be compared.
        @test (MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) ==
            (MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test (MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) !=
                (MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test (MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) !=
                (MOI.EqualTo(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test (MOI.GreaterThan(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) !=
                (MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test (MOI.EqualTo(1.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0)) !=
                (MOI.GreaterThan(0.0), MOI.EqualTo(0.0), MOI.EqualTo(0.0))
        @test (MOI.EqualTo(1), MOI.EqualTo(0), MOI.EqualTo(0)) !=
                (MOI.GreaterThan(0), MOI.EqualTo(0), MOI.EqualTo(0))
        @test (CP.Domain(Set([0, 1])),) == (CP.Domain(Set([0, 1])),)

        # Then, wrap the tuples in conjunctions and disjunctions.
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
        @test S((MOI.EqualTo(1), MOI.EqualTo(0), MOI.EqualTo(0))) !=
              S((MOI.GreaterThan(0), MOI.EqualTo(0), MOI.EqualTo(0)))
        @test S((CP.Domain(Set([0, 1])), MOI.EqualTo(0))) ==
              S((CP.Domain(Set([0, 1])), MOI.EqualTo(0)))
        @test S((CP.Domain(Set([0, 1])),)) == S((CP.Domain(Set([0, 1])),))

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

    @testset "ValuePrecedence" begin
        @test CP.ValuePrecedence(1, 4, 20) == CP.ValuePrecedence(1, 4, 20)
        @test CP.ValuePrecedence(1, 4, 20) != CP.ValuePrecedence(1, 4, 25)
        @test CP.ValuePrecedence(1, 4, 20) != CP.ValuePrecedence(1, 5, 20)
        @test CP.ValuePrecedence(1, 4, 20) != CP.ValuePrecedence(2, 4, 20)

        s = CP.ValuePrecedence(1, 4, 20)
        @test typeof(copy(s)) <: CP.ValuePrecedence
        @test copy(s) == s

        @test MOI.dimension(CP.ValuePrecedence(1, 4, 20)) == 20
        @test MOI.dimension(CP.ValuePrecedence(1, 5, 20)) == 20
        @test MOI.dimension(CP.ValuePrecedence(2, 4, 20)) == 20
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

    @testset "GlobalCardinality family" begin
        @testset "Constructor" begin
            for CVCT in [CP.OPEN_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES]
                @test_throws ErrorException CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CVCT, Int}(4, Int[], 5)
                @test_throws ErrorException CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CVCT, Int}(4, [4, 5], -1)
            end
        end

        @testset "GlobalCardinality{FIXED_COUNTED_VALUES, $(CVCT), Int}" for CVCT in [CP.OPEN_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES]
            @test CP.GlobalCardinality{CVCT}(2, [2, 4]) == CP.GlobalCardinality{CVCT}(2, [2, 4])
            @test CP.GlobalCardinality{CVCT}(2, [2, 4]) != CP.GlobalCardinality{CVCT}(3, [2, 4])
            @test CP.GlobalCardinality{CVCT}(3, [2, 4]) != CP.GlobalCardinality{CVCT}(2, [2, 4])
            @test CP.GlobalCardinality{CVCT}(2, [2, 4]) != CP.GlobalCardinality{CVCT}(2, [3, 5])

            s = CP.GlobalCardinality{CVCT}(2, [2, 4])
            @test typeof(copy(s)) <: CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CVCT, Int}
            @test copy(s) == s

            @test MOI.dimension(CP.GlobalCardinality{CVCT}(2, [2, 4])) == 2 + 2
            @test MOI.dimension(CP.GlobalCardinality{CVCT}(3, [2, 4, 6, 8])) == 3 + 4

            if CVCT == CP.OPEN_COUNTED_VALUES
                @test CP.GlobalCardinality{CVCT}(2, [2, 4]) == CP.GlobalCardinality(2, [2, 4])
            end
        end

        @testset "GlobalCardinality{VARIABLE_COUNTED_VALUES, $(CVCT), Int}" for CVCT in [CP.OPEN_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES]
            @test CP.GlobalCardinality{CVCT, Int}(2, 2) == CP.GlobalCardinality{CVCT, Int}(2, 2)
            @test CP.GlobalCardinality{CVCT, Int}(2, 2) != CP.GlobalCardinality{CVCT, Int}(3, 3)
            @test CP.GlobalCardinality{CVCT, Int}(3, 2) != CP.GlobalCardinality{CVCT, Int}(2, 2)
            @test CP.GlobalCardinality{CVCT, Int}(2, 2) != CP.GlobalCardinality{CVCT, Int}(2, 3)

            s = CP.GlobalCardinality{CVCT, Int}(2, 2)
            @test typeof(copy(s)) <: CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CVCT, Int}
            @test copy(s) == s

            @test MOI.dimension(CP.GlobalCardinality{CVCT, Int}(2, 2)) == 2 + 2 * 2
            @test MOI.dimension(CP.GlobalCardinality{CVCT, Int}(3, 4)) == 3 + 2 * 4

            if CVCT == CP.OPEN_COUNTED_VALUES
                @test CP.GlobalCardinality{CVCT, Int}(2, 3) == CP.GlobalCardinality{Int}(2, 3)
            end
        end
    end

    @testset "CumulativeResource family" begin
        @testset "CumulativeResource{$(CRDT)}" for CRDT in [
            CP.NO_DEADLINE_CUMULATIVE_RESOURCE,
            CP.VARIABLE_DEADLINE_CUMULATIVE_RESOURCE,
        ]
            @test CP.CumulativeResource{CRDT}(2) == CP.CumulativeResource{CRDT}(2)
            @test CP.CumulativeResource{CRDT}(2) != CP.CumulativeResource{CRDT}(3)
            @test CP.CumulativeResource{CRDT}(3) != CP.CumulativeResource{CRDT}(2)

            s = CP.CumulativeResource{CRDT}(2)
            @test typeof(copy(s)) <: CP.CumulativeResource{CRDT}
            @test copy(s) == s

            if CRDT == CP.NO_DEADLINE_CUMULATIVE_RESOURCE
                @test MOI.dimension(CP.CumulativeResource{CRDT}(2)) == 2 * 3 + 1
                @test MOI.dimension(CP.CumulativeResource{CRDT}(3)) == 3 * 3 + 1
            elseif CRDT == CP.VARIABLE_DEADLINE_CUMULATIVE_RESOURCE
                @test MOI.dimension(CP.CumulativeResource{CRDT}(2)) == 2 * 4 + 1
                @test MOI.dimension(CP.CumulativeResource{CRDT}(3)) == 3 * 4 + 1
            else
                @assert false
            end
        end
        
        @test CP.CumulativeResource(2) == CP.CumulativeResource(2)
        @test CP.CumulativeResource(2) != CP.CumulativeResource(3)
        @test CP.CumulativeResource(3) != CP.CumulativeResource(2)

        s = CP.CumulativeResource(2)
        @test typeof(copy(s)) <: CP.CumulativeResource{CP.NO_DEADLINE_CUMULATIVE_RESOURCE}
        @test copy(s) == s

        @test MOI.dimension(CP.CumulativeResource(2)) == 2 * 3 + 1
        @test MOI.dimension(CP.CumulativeResource(3)) == 3 * 3 + 1
    end

    @testset "BinPacking family" begin
        @testset "BinPacking{NO_CAPACITY_BINPACKING}" begin
            @test_throws AssertionError CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [1, 2, 3])

            @test CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [1, 2]) == CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [1, 2])
            @test CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(2, 2, [1, 2]) != CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [1, 2])
            @test CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 3, [1, 2, 3]) != CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [1, 2])

            s = CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [1, 2])
            @test typeof(copy(s)) <: CP.BinPacking{CP.NO_CAPACITY_BINPACKING}
            @test copy(s) == s

            @test MOI.dimension(CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [1, 2])) == 3
            
            @test_throws AssertionError CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [-1, 2])
            @test_throws AssertionError CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(0, 2, [1, 2])
            @test_throws AssertionError CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 0, [1, 2])
        end

        @testset "BinPacking{FIXED_CAPACITY_BINPACKING}" begin
            @test_throws AssertionError CP.BinPacking(
                1,
                2,
                [1, 2, 3],
                [4],
            )
            @test_throws AssertionError CP.BinPacking(
                1,
                2,
                [1, 2],
                [3, 4],
            )
            @test_throws AssertionError CP.BinPacking(
                1,
                2,
                [1, 2, 3],
                [4, 5],
            )

            @test CP.BinPacking(1, 2, [1, 2], [4]) ==
                CP.BinPacking(1, 2, [1, 2], [4])
            @test CP.BinPacking(2, 2, [1, 2], [4, 5]) !=
                CP.BinPacking(1, 2, [1, 2], [4])
            @test CP.BinPacking(1, 3, [1, 2, 3], [4]) !=
                CP.BinPacking(1, 2, [1, 2], [4])

            s = CP.BinPacking(1, 2, [1, 2], [4])
            @test typeof(copy(s)) <: CP.BinPacking{CP.FIXED_CAPACITY_BINPACKING, Int}
            @test copy(s) == s

            @test MOI.dimension(CP.BinPacking(1, 2, [1, 2], [4])) == 3

            @test_throws AssertionError CP.BinPacking(1, 2, [-1, 2], [4])
            @test_throws AssertionError CP.BinPacking(1, 2, [1, 2], [-4])
            @test_throws AssertionError CP.BinPacking(0, 2, [1, 2], [4])
            @test_throws AssertionError CP.BinPacking(1, 0, [1, 2], [4])
        end

        @testset "BinPacking{VARIABLE_CAPACITY_BINPACKING}" begin
            @test_throws AssertionError CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(
                1,
                2,
                [1, 2, 3],
            )

            @test CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(1, 2, [1, 2]) ==
                CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(1, 2, [1, 2])
            @test CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(2, 2, [1, 2]) !=
                CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(1, 2, [1, 2])
            @test CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(1, 3, [1, 2, 3]) !=
                CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(1, 2, [1, 2])

            s = CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(1, 2, [1, 2])
            @test typeof(copy(s)) <: CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}
            @test copy(s) == s

            @test MOI.dimension(CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(1, 2, [1, 2])) == 4

            @test_throws AssertionError CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(1, 2, [-1, 2])
            @test_throws AssertionError CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(0, 2, [1, 2])
            @test_throws AssertionError CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING}(1, 0, [1, 2])
        end
    end

    @testset "Knapsack family" begin
        # @testset "Easy constructor" begin
        #     @test_throws UndefKeywordError CP.Knapsack(capacity=1)

        #     @test CP.Knapsack(weights=[1, 2]) == CP.Knapsack([1, 2])
        #     @test CP.Knapsack(weights=[1, 2]) == CP.Knapsack{VARIABLE_CAPACITY_KNAPSACK, UNVALUED_KNAPSACK, Int}([1, 2])
        # end

        @testset "Knapsack{FIXED_CAPACITY_KNAPSACK, UNVALUED_KNAPSACK}" begin
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

        @testset "Knapsack{VARIABLE_CAPACITY_KNAPSACK, UNVALUED_KNAPSACK}" begin
            @test CP.Knapsack([1, 2, 3]) == CP.Knapsack([1, 2, 3])

            s = CP.Knapsack([1, 2, 3])
            @test typeof(copy(s)) <: CP.Knapsack{CP.VARIABLE_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK}
            @test copy(s) == s

            @test MOI.dimension(CP.Knapsack([1, 2, 3])) == 3 + 1

            @test_throws AssertionError CP.Knapsack([-1, 2, 3])
        end

        @testset "Knapsack{FIXED_CAPACITY_KNAPSACK, VALUED_KNAPSACK}" begin
            @test CP.Knapsack([1, 2, 3], 3, [1, 2, 3]) == CP.Knapsack([1, 2, 3], 3, [1, 2, 3])
            @test CP.Knapsack([1, 2, 3], 3, [1, 2, 3]) != CP.Knapsack([1, 2, 3], 4, [1, 2, 3])
            @test CP.Knapsack([1, 2, 3], 4, [1, 2, 3]) != CP.Knapsack([1, 2, 3], 3, [1, 2, 3])

            s = CP.Knapsack([1, 2, 3], 3, [1, 2, 3])
            @test typeof(copy(s)) <: CP.Knapsack
            @test copy(s) == s

            @test MOI.dimension(CP.Knapsack([1, 2, 3], 3, [1, 2, 3])) == 3 + 1

            @test_throws AssertionError CP.Knapsack([-1, 2, 3], 3, [1, 2, 3])
            @test_throws AssertionError CP.Knapsack([1, 2, 3], 3, [-1, 2, 3])
            @test_throws AssertionError CP.Knapsack([1, 2, 3], -3, [1, 2, 3])
        end

        @testset "Knapsack{VARIABLE_CAPACITY_KNAPSACK, VALUED_KNAPSACK}" begin
            @test CP.Knapsack([1, 2, 3], [1, 2, 3]) == CP.Knapsack([1, 2, 3], [1, 2, 3])

            s = CP.Knapsack([1, 2, 3], [1, 2, 3])
            @test typeof(copy(s)) <: CP.Knapsack{CP.VARIABLE_CAPACITY_KNAPSACK, CP.VALUED_KNAPSACK}
            @test copy(s) == s

            @test MOI.dimension(CP.Knapsack([1, 2, 3], [1, 2, 3])) == 3 + 2

            @test_throws AssertionError CP.Knapsack([-1, 2, 3], [1, 2, 3])
            @test_throws AssertionError CP.Knapsack([1, 2, 3], [-1, 2, 3])
        end
    end

    @testset "NonOverlappingOrthotopes family" begin
        for NOOCT in [
            CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES,
            CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES,
        ]
            @test isbitstype(CP.NonOverlappingOrthotopes{NOOCT})

            @test CP.NonOverlappingOrthotopes{NOOCT}(2, 2) == CP.NonOverlappingOrthotopes{NOOCT}(2, 2)
            @test CP.NonOverlappingOrthotopes{NOOCT}(2, 2) != CP.NonOverlappingOrthotopes{NOOCT}(2, 1)
            @test CP.NonOverlappingOrthotopes{NOOCT}(2, 2) != CP.NonOverlappingOrthotopes{NOOCT}(3, 2)
            @test CP.NonOverlappingOrthotopes{NOOCT}(3, 2) != CP.NonOverlappingOrthotopes{NOOCT}(2, 2)

            s = CP.NonOverlappingOrthotopes{NOOCT}(2, 2)
            @test typeof(copy(s)) <: CP.NonOverlappingOrthotopes{NOOCT}
            @test copy(s) == s

            if NOOCT == CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES
                @test MOI.dimension(CP.NonOverlappingOrthotopes{NOOCT}(2, 2)) == 3 * 2 * 2
                @test MOI.dimension(CP.NonOverlappingOrthotopes{NOOCT}(3, 4)) == 3 * 3 * 4
            elseif NOOCT == CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES
                @test MOI.dimension(CP.NonOverlappingOrthotopes{NOOCT}(2, 2)) == 3 * 2 * 2 + 2
                @test MOI.dimension(CP.NonOverlappingOrthotopes{NOOCT}(3, 4)) == 3 * 3 * 4 + 3
            else
                error("$(NOOCT) not implemented")
            end

            if NOOCT == CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES
                @test CP.NonOverlappingOrthotopes{NOOCT}(2, 2) == CP.NonOverlappingOrthotopes(2, 2)
            end
        end
    end
end
