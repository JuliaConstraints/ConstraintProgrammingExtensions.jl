@testset "provisional XCSP3 sets" begin
    all_different = CP.XCSP3AllDifferent(4; except = [0])
    @test MOI.dimension(all_different) == 4
    @test copy(all_different) == all_different
    @test CP.semantic_id(all_different) == :all_different
    @test CP.semantic_variant(all_different) == :xcsp3

    fixed_sum = CP.XCSP3Sum(3;
        coefficients = CP.XCSP3Constants([2, -1, 3]),
        condition = CP.XCSP3Condition(:le, 7),
    )
    @test MOI.dimension(fixed_sum) == 3
    @test copy(fixed_sum) == fixed_sum
    @test CP.semantic_id(fixed_sum) == :sum

    variable_target = CP.XCSP3Sum(3;
        condition = CP.XCSP3Condition(:eq, CP.XCSP3Variable()),
    )
    @test MOI.dimension(variable_target) == 4

    variable_coefficients = CP.XCSP3Sum(3;
        coefficients = CP.XCSP3Variables(3),
        condition = CP.XCSP3Condition(:ge, CP.XCSP3Variable()),
    )
    @test MOI.dimension(variable_coefficients) == 7

    set_operand = CP.XCSP3Sum(2;
        condition = CP.XCSP3Condition(:in, Set([2, 4])),
    )
    @test MOI.dimension(set_operand) == 2
    @test copy(set_operand) == set_operand

    @test MOI.dimension(CP.XCSP3AllDifferent(1)) == 1
    @test MOI.dimension(CP.XCSP3Sum(1;
        condition = CP.XCSP3Condition(:eq, 0),
    )) == 1
    @test_throws ArgumentError CP.XCSP3AllDifferent(0)
    @test_throws DimensionMismatch CP.XCSP3Sum(3;
        coefficients = CP.XCSP3Constants([1, 2]),
        condition = CP.XCSP3Condition(:eq, 0),
    )
    @test_throws ArgumentError CP.XCSP3Condition(:in, 2)
    @test_throws ArgumentError CP.XCSP3Condition(:eq, CP.XCSP3Interval(1, 2))
    @test isempty(CP.XCSP3ValueSet(Set{Int}()).values)
    @test_throws ArgumentError CP.XCSP3Constant(MOI.VariableIndex(1))
    @test_throws ArgumentError CP.XCSP3Constants([MOI.VariableIndex(1)])
    @test_throws ArgumentError CP.XCSP3AllDifferent(
        2; except = [MOI.VariableIndex(1)])
end

@testset "XCSP3 counting layouts and ownership" begin
    condition = CP.XCSP3Condition(:eq, CP.XCSP3Variable())
    count = CP.XCSP3Count(3; values = CP.XCSP3Variables(2), condition)
    nvalues = CP.XCSP3NValues(1; except = [0], condition)
    cardinality = CP.XCSP3Cardinality(3;
        values = CP.XCSP3Variables(2), occurs = CP.XCSP3Variables(2))
    for (set, dimension, identity) in ((count, 6, :count), (nvalues, 2, :nvalues),
            (cardinality, 7, :cardinality))
        @test MOI.dimension(set) == dimension
        @test copy(set) == set
        @test CP.semantic_id(set) == CP.semantic_id(typeof(set)) == identity
        @test CP.semantic_variant(set) == :xcsp3
    end
    @test !cardinality.closed
    @test cardinality == CP.XCSP3Cardinality(3;
        values = CP.XCSP3Variables(2), occurs = CP.XCSP3Variables(2), closed = false)
    closed_cardinality = CP.XCSP3Cardinality(3;
        values = CP.XCSP3Variables(2), occurs = CP.XCSP3Variables(2), closed = true)
    @test closed_cardinality.closed
    @test copy(closed_cardinality) == closed_cardinality
    @test closed_cardinality != cardinality
    @test CP.GlobalCardinality(3, [1, 2]) isa
        CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES}
    for n in (1, 3), variable_values in (false, true), variable_occurs in (false, true)
        set = CP.XCSP3Cardinality(n;
            values = variable_values ? CP.XCSP3Variables(2) : CP.XCSP3Constants([1, 2]),
            occurs = variable_occurs ? CP.XCSP3Variables(2) : CP.XCSP3Constants([0:1, 1:3]))
        @test MOI.dimension(set) == n + 2variable_values + 2variable_occurs
    end
    for set in (CP.XCSP3Count(1; values = CP.XCSP3Constants([1, 2]),
                    condition = CP.XCSP3Condition(:in, Set([0, 1]))),
            CP.XCSP3Cardinality(1; values = CP.XCSP3Constants([1, 2]),
                occurs = CP.XCSP3Constants(Any[1, 0:2])))
        duplicate = copy(set)
        @test duplicate == set
        duplicate.values.values[1] = 7
        @test set.values.values[1] == 1
    end
    duplicate = copy(nvalues)
    push!(duplicate.except, 2)
    @test nvalues.except == [0]
    for operand in (CP.XCSP3Constants([1]), CP.XCSP3Variables(1))
        @test_throws ArgumentError CP.XCSP3Condition(:eq, operand)
    end
    @test_throws ArgumentError CP.XCSP3Count(0; values = CP.XCSP3Constants([1]), condition)
    @test_throws ArgumentError CP.XCSP3NValues(0; condition)
    @test_throws ArgumentError CP.XCSP3NValues(1; except = [MOI.VariableIndex(1)], condition)
    @test_throws DimensionMismatch CP.XCSP3Cardinality(1;
        values = CP.XCSP3Constants([1]), occurs = CP.XCSP3Constants([1, 2]))
    for invalid in ([-1], [2:1], [0:2:4], [0.5])
        @test_throws ArgumentError CP.XCSP3Cardinality(1;
            values = CP.XCSP3Constants([1]), occurs = CP.XCSP3Constants(invalid))
    end
end
