@testset "GlobalCardinalityFixedOpen2Count: $(fct_type), $(array_size) items, $(sought_size) sought items, $(T)" for fct_type in ["vector of variables", "vector affine function"], array_size in [2, 3], sought_size in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(CountModel{T}())
    model = COIB.GlobalCardinalityFixedOpen2Count{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Count{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.GlobalCardinality{T},
    )

    x_counts, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:sought_size])
    sought_values = T(5) .+ collect(1:sought_size)
    
    if T == Int
        x_array, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:array_size])
    elseif T == Float64
        x_array = MOI.add_variables(model, array_size)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_array..., x_counts...])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_array..., x_counts...]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.GlobalCardinality(array_size, sought_values))

    for i in 1:array_size
        @test MOI.is_valid(model, x_array[i])
    end
    for i in 1:sought_size
        @test MOI.is_valid(model, x_counts[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.GlobalCardinality{T}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.GlobalCardinality{T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}}()) == sought_size

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}}()) == bridge.cons_count
    end

    @testset "Sought array" begin
        @test length(bridge.cons_count) == sought_size
        for i in 1:sought_size
            @test MOI.is_valid(model, bridge.cons_count[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_count[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_count[i]) == CP.Count(array_size, MOI.EqualTo(sought_values[i]))

            @test length(f.terms) == 1 + array_size
            for i in 1:(1 + array_size)
                @test f.terms[i].output_index == i
                @test f.terms[i].scalar_term.coefficient === one(T)
            end
            @test f.terms[1].scalar_term.variable_index === x_counts[i]
            for i in 1:array_size
                @test f.terms[1 + i].scalar_term.variable_index === x_array[i]
            end
        end
    end
end
