@testset "LexicographicallyLessThan2Indicator: $(fct_type), $(x_size) × $(y_size), $(T)" for fct_type in ["vector of variables", "vector affine function"], x_size in [2, 4], y_size in [2, 4], T in [Int, Float64]
    base_model = if T == Int
        IntIndicatorMILPModel{T}()
    elseif T == Float64
        FloatIndicatorMILPModel{T}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.LexicographicallyLessThan2Indicator{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.LexicographicallyLessThan,
    )
    
    if T == Int
        x_array, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:(x_size * y_size)])
    elseif T == Float64
        x_array = MOI.add_variables(model, x_size * y_size)
    end
    x_matrix = reshape(x_array, x_size, y_size)

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables(x_array)
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.(x_array))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.LexicographicallyLessThan(y_size, x_size))

    for i in 1:(x_size * y_size)
        @test MOI.is_valid(model, x_array[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.LexicographicallyLessThan}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.LexicographicallyLessThan) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
            (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}),
            (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 2 * (x_size - 1) * y_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == 2 * (x_size - 1) * y_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == x_size - 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == (x_size - 1) * (y_size - 1)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}()) == (x_size - 1) * y_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}}()) == (x_size - 1) * y_size

        @test Set(MOI.get(bridge, MOI.ListOfVariableIndices())) == Set([bridge.vars_eq..., bridge.vars_lt...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}())) == Set([bridge.vars_eq_bin..., bridge.vars_lt_bin...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}())) == Set(bridge.cons_one_lt)
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}())) == Set(bridge.cons_move)
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}())) == Set(bridge.cons_indic_eq)
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}}())) == Set(bridge.cons_indic_lt)
    end

    @testset "Sets of variables" begin
        @test length(bridge.vars_eq) == (x_size - 1) * y_size
        @test length(bridge.vars_lt) == (x_size - 1) * y_size

        for i in 1:(x_size - 1)
            # For each pair of columns (i, i+1)...
            @test length(bridge.vars_eq[i, :]) == y_size
            @test length(bridge.vars_lt[i, :]) == y_size

            for j in 1:y_size
                # For each pair of elements in the columns...
                @test MOI.is_valid(model, bridge.vars_eq[i, j])
                @test MOI.is_valid(model, bridge.vars_lt[i, j])
                @test MOI.is_valid(model, bridge.vars_eq_bin[i, j])
                @test MOI.is_valid(model, bridge.vars_lt_bin[i, j])
                
                @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_eq_bin[i, j]) == MOI.ZeroOne()
                @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_lt_bin[i, j]) == MOI.ZeroOne()
                @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_eq_bin[i, j]) == MOI.SingleVariable(bridge.vars_eq[i, j])
                @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_lt_bin[i, j]) == MOI.SingleVariable(bridge.vars_lt[i, j])
            end
        end
    end

    @testset "Constraint: at most one less-than pair of values per pair of columns" begin
        @test length(bridge.cons_one_lt) == (x_size - 1)

        for i in 1:(x_size - 1)
            # For each pair of columns (i, i+1)...
            @test MOI.is_valid(model, bridge.cons_one_lt[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_one_lt[i]) == MOI.LessThan(one(T))

            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_one_lt[i])
            @test length(f.terms) == y_size
            @test f.constant == zero(T)

            for j in 1:y_size
                t = f.terms[j]
                @test t.coefficient === one(T)
                @test t.variable_index == bridge.vars_lt[i, j]
            end
        end
    end

    @testset "Constraint: recursive definition starting at the end of the arrays" begin
        @test length(bridge.cons_move) == (x_size - 1) * (y_size - 1)

        for i in 1:(x_size - 1)
            # For each pair of columns (i, i+1)...
            @test length(bridge.cons_move[i, :]) == y_size - 1

            for j in 1:(y_size - 1)
                # For each pair of elements in the columns...
                @test MOI.is_valid(model, bridge.cons_move[i, j])
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_move[i, j]) == MOI.EqualTo(zero(T))

                f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_move[i, j])
                @test length(f.terms) == 3
                @test f.constant == zero(T)

                t1 = f.terms[1]
                @test t1.coefficient === one(T)
                @test t1.variable_index == bridge.vars_eq[i, j]

                t2 = f.terms[2]
                @test t2.coefficient === -one(T)
                @test t2.variable_index == bridge.vars_eq[i, j + 1]

                t3 = f.terms[3]
                @test t3.coefficient === -one(T)
                @test t3.variable_index == bridge.vars_lt[i, j + 1]
            end
        end
    end

    @testset "Constraint: indicator for equality" begin
        @test length(bridge.cons_indic_eq) == (x_size - 1) * y_size

        for i in 1:(x_size - 1)
            # For each pair of columns (i, i+1)...
            @test length(bridge.cons_indic_eq[i, :]) == y_size

            for j in 1:y_size
                # For each pair of elements in the columns...
                @test MOI.is_valid(model, bridge.cons_indic_eq[i, j])
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_indic_eq[i, j]) == MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo(zero(T)))

                f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_indic_eq[i, j])
                @test length(f.terms) == 3
                @test f.constants == zeros(T, 2)

                t1 = f.terms[1]
                @test t1.output_index == 1
                @test t1.scalar_term.coefficient === one(T)
                @test t1.scalar_term.variable_index == bridge.vars_eq[i, j]

                t2 = f.terms[2]
                @test t2.output_index == 2
                @test t2.scalar_term.coefficient === one(T)
                @test t2.scalar_term.variable_index == x_matrix[i, j]

                t3 = f.terms[3]
                @test t3.output_index == 2
                @test t3.scalar_term.coefficient === -one(T)
                @test t3.scalar_term.variable_index == x_matrix[i + 1, j]
            end
        end
    end

    @testset "Constraint: indicator for inequality" begin
        @test length(bridge.cons_indic_lt) == (x_size - 1) * y_size

        for i in 1:(x_size - 1)
            # For each pair of columns (i, i+1)...
            @test length(bridge.cons_indic_lt[i, :]) == y_size

            for j in 1:y_size
                # For each pair of elements in the columns...
                @test MOI.is_valid(model, bridge.cons_indic_lt[i, j])
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_indic_lt[i, j]) == MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(MOI.LessThan(zero(T)))

                f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_indic_lt[i, j])
                @test length(f.terms) == 3
                @test f.constants == zeros(T, 2)

                t1 = f.terms[1]
                @test t1.output_index == 1
                @test t1.scalar_term.coefficient === one(T)
                @test t1.scalar_term.variable_index == bridge.vars_lt[i, j]

                t2 = f.terms[2]
                @test t2.output_index == 2
                @test t2.scalar_term.coefficient === one(T)
                @test t2.scalar_term.variable_index == x_matrix[i, j]

                t3 = f.terms[3]
                @test t3.output_index == 2
                @test t3.scalar_term.coefficient === -one(T)
                @test t3.scalar_term.variable_index == x_matrix[i + 1, j]
            end
        end
    end
end
    