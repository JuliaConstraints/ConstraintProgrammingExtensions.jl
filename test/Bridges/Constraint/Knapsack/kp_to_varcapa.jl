@testset "Knapsack2VariableCapacityKnapsackBridge: $(fct_type), 2 items, $(T)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    mock = MOIU.MockOptimizer(VariableCapacityKnapsackModel{T}())
    model = COIB.Knapsack2VariableCapacityKnapsack{T}(mock)

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
        CP.Knapsack{CP.VARIABLE_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T},
    )

    n_items = 2
    weights = T[3, 2]
    capacity = T(5)

    x_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x_2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_1, x_2])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_1, x_2]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Knapsack(weights, capacity))

    @test MOI.is_valid(model, x_1)
    @test MOI.is_valid(model, x_2)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Knapsack{T}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Knapsack{T}) == typeof(bridge)
        if T == Int
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.Integer,)]
        elseif T == Float64
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        else 
            @assert false
        end
        @test Set(MOIB.added_constraint_types(typeof(bridge))) == Set([
            (MOI.VectorAffineFunction{T}, CP.Knapsack{CP.VARIABLE_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T}),
        ])

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Knapsack{CP.VARIABLE_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T}}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}()) == ((T == Int) ? 1 : 0)

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == [bridge.capa_var]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Knapsack{CP.VARIABLE_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T}}()) == [bridge.kp]
        if T == Int
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.Integer}()) == [bridge.capa_con]
        end
    end

    @testset "BinPacking constraint" begin
        @test MOI.is_valid(model, bridge.kp)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.kp)
        @test length(f.terms) == n_items + 1
        for i in 1:n_items + 1
            @test f.terms[i].output_index == i
            @test f.terms[i].scalar_term.coefficient === one(T)
        end
        @test f.terms[1].scalar_term.variable_index == x_1
        @test f.terms[2].scalar_term.variable_index == x_2
        @test f.terms[3].scalar_term.variable_index == bridge.capa_var
        @test MOI.get(model, MOI.ConstraintSet(), bridge.kp) == CP.Knapsack(weights)
    end
end
