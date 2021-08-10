@testset "ValuedKnapsack2MILP: $(fct_type), 2 items, $(T)" for fct_type in ["vector of variables"], T in [Int]# for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.ValuedKnapsack2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    )
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.VALUED_KNAPSACK, T},
    )

    n_items = 2
    weights = T[3, 2]
    values = T[8, 1]
    capacity = T(5)

    x_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x_2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    if T == Int
        x_value, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x_value = MOI.add_variable(model)
    else
        @assert false
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_1, x_2, x_value])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_1, x_2, x_value]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Knapsack(weights, capacity, values))

    @test MOI.is_valid(model, x_1)
    @test MOI.is_valid(model, x_2)
    @test MOI.is_valid(model, x_value)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Knapsack{T}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Knapsack{T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == [bridge.kp]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.value]
    end

    @testset "Relation between the integer and binary representation of bin assignment" begin
        @test MOI.is_valid(model, bridge.kp)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.kp)
        @test length(f.terms) == n_items
        @test f.constant === -capacity
        @test MOI.get(model, MOI.ConstraintSet(), bridge.kp) == MOI.LessThan(zero(T))

        for item in 1:n_items
            t = f.terms[item]
            @test t.coefficient === weights[item]
            @test t.variable_index == ((item == 1) ? x_1 : x_2)
        end
    end

    @testset "Value" begin
        @test MOI.is_valid(model, bridge.value)
        @test MOI.get(model, MOI.ConstraintSet(), bridge.value) == MOI.EqualTo(zero(T))
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.value)

        @test length(f.terms) == n_items + 1
        @test f.constant === zero(T)

        for item in 1:n_items
            t = f.terms[item]
            @test t.coefficient === values[item]
            @test t.variable_index == ((item == 1) ? x_1 : x_2)
        end
        
        t = f.terms[end]
        @test t.coefficient === -one(T)
        @test t.variable_index == x_value
    end
end
