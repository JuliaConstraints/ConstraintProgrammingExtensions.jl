@testset "VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige: $(fct_type), 2 items, $(T)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    mock = MOIU.MockOptimizer(VariableCapacityKnapsackModel{T}())
    model = COIB.VariableCapacityValuedKnapsack2VariableCapacityKnapsack{T}(mock)

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
        MOI.VectorOfVariables,
        CP.VariableCapacityKnapsack{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.VariableCapacityValuedKnapsack{T},
    )

    n_items = 2
    weights = T[3, 2]
    values = T[8, 1]

    x_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x_2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    if T == Int
        x_value, _ = MOI.add_constrained_variable(model, MOI.Integer())
        x_capa, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x_value = MOI.add_variable(model)
        x_capa = MOI.add_variable(model)
    else
        @assert false
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_1, x_2, x_capa, x_value])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_1, x_2, x_capa, x_value]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.VariableCapacityValuedKnapsack(weights, values))

    @test MOI.is_valid(model, x_1)
    @test MOI.is_valid(model, x_2)
    @test MOI.is_valid(model, x_value)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.VariableCapacityValuedKnapsack{T}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.VariableCapacityValuedKnapsack{T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test Set(MOIB.added_constraint_types(typeof(bridge))) == Set([
            (MOI.VectorAffineFunction{T}, CP.VariableCapacityKnapsack{T}),
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        ])

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.VariableCapacityKnapsack{T}}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.VariableCapacityKnapsack{T}}()) == [bridge.kp]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.value]
    end

    @testset "Value constraint" begin
        @test MOI.is_valid(model, bridge.kp)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.value)
        @test length(f.terms) == n_items + 1
        for i in 1:n_items
            @test f.terms[i].coefficient === values[i]
        end
        @test f.terms[end].coefficient === -one(T)

        @test f.terms[1].variable_index == x_1
        @test f.terms[2].variable_index == x_2
        @test f.terms[3].variable_index == x_value
        @test MOI.get(model, MOI.ConstraintSet(), bridge.value) == MOI.EqualTo(zero(T))
    end

    @testset "BinPacking constraint" begin
        @test MOI.is_valid(model, bridge.kp)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.kp)
        @test length(f.terms) == n_items + 1
        for i in 1:n_items
            @test f.terms[i].output_index == i
            @test f.terms[i].scalar_term.coefficient === one(T)
        end
        @test f.terms[1].scalar_term.variable_index == x_1
        @test f.terms[2].scalar_term.variable_index == x_2
        @test f.terms[3].scalar_term.variable_index == x_capa
        @test MOI.get(model, MOI.ConstraintSet(), bridge.kp) == CP.VariableCapacityKnapsack(weights)
    end
end
