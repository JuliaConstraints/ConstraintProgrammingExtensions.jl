@testset "GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpen: $(fct_type), $(array_size) items, $(sought_size) sought items, $(T)" for fct_type in ["vector of variables", "vector affine function"], array_size in [2, 3], sought_size in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(GlobalCardinalityModel{T}())
    model = COIB.GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpen{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.GlobalCardinalityFixedOpen{T},
    )
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        CP.Domain{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T},
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
    c = MOI.add_constraint(model, fct, CP.GlobalCardinality{CP.CLOSED_COUNTED_VALUES}(array_size, sought_values))

    for i in 1:array_size
        @test MOI.is_valid(model, x_array[i])
    end
    for i in 1:sought_size
        @test MOI.is_valid(model, x_counts[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, CP.Domain{T}),
            (MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, CP.Domain{T}}()) == array_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}}()) == 1
        
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, CP.Domain{T}}()) == bridge.cons_domain
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}}()) == [bridge.con_gc]
    end

    @testset "Domain" begin
        @test length(bridge.cons_domain) == array_size
        for i in 1:array_size
            @test MOI.is_valid(model, bridge.cons_domain[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_domain[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_domain[i]) == CP.Domain(Set(sought_values))

            @test length(f.terms) == 1

            @test f.terms[1].coefficient === one(T)
            @test f.terms[1].variable_index === x_array[i]
        end
    end

    @testset "Global cardinality" begin
        @test MOI.is_valid(model, bridge.con_gc)
        f = MOIU.canonical(MOI.get(model, MOI.ConstraintFunction(), bridge.con_gc))
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_gc) == CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES}(array_size, sought_values)

        # f == fct, in principle, with the exception that the bridge always 
        # uses a VectorAffineFunction, even if the input is a VectorOfVariables.
        @test length(f.terms) == array_size + sought_size
        @test f.constants == zeros(T, array_size + sought_size)

        for i in 1:(array_size + sought_size)
            t = f.terms[i]
            @test t.output_index == i
            @test t.scalar_term.coefficient === one(T)

            if 1 <= i <= array_size
                @test t.scalar_term.variable_index == x_array[i]
            else
                @test t.scalar_term.variable_index == x_counts[i - array_size]
            end
        end
    end
end
