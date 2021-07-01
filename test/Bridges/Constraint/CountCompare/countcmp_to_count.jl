@testset "CountCompare2Count: $(fct_type), $(array_size) items, $(T)" for fct_type in ["vector of variables"], array_size in [2], T in [Int]
    # for fct_type in ["vector of variables", "vector affine function"], array_size in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(CountModel{T}())
    model = COIB.CountCompare2Count{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Count{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.CountCompare,
    )

    x_count, _ = MOI.add_constrained_variable(model, MOI.Integer())
    
    if T == Int
        x_array_1, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:array_size])
        x_array_2, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:array_size])
    elseif T == Float64
        x_array_1 = MOI.add_variables(model, array_size)
        x_array_2 = MOI.add_variables(model, array_size)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_count, x_array_1..., x_array_2...])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_count, x_array_1..., x_array_2...]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.CountCompare(array_size))

    @test MOI.is_valid(model, x_count)
    for i in 1:array_size
        @test MOI.is_valid(model, x_array_1[i])
        @test MOI.is_valid(model, x_array_2[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.CountCompare}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Count{MOI.EqualTo{T}}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}}()) == [bridge.con]
    end

    @testset "Sum" begin
        @test MOI.is_valid(model, bridge.con)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con)
        @test length(f.terms) == 2 * array_size + 1
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con) == CP.Count(array_size, MOI.EqualTo(zero(T)))

        t = f.terms[1]
        @test t.output_index == 1
        @test t.scalar_term.coefficient === one(T)
        @test t.scalar_term.variable_index == x_count

        for i in 1:array_size
            t1 = f.terms[2 + 2 * (i - 1)]
            @test t1.output_index == 1 + i
            @test t1.scalar_term.coefficient === one(T)
            @test t1.scalar_term.variable_index == x_array_1[i]

            t2 = f.terms[3 + 2 * (i - 1)]
            @test t2.output_index == 1 + i
            @test t2.scalar_term.coefficient === -one(T)
            @test t2.scalar_term.variable_index == x_array_2[i]
        end
    end
end
