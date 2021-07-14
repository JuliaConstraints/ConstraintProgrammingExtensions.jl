@testset "ClosedGlobalCardinalityVariable2GlobalCardinalityVariable: $(fct_type), $(array_size) items, $(sought_size) sought items, $(T)" for fct_type in ["vector of variables"], array_size in [2], sought_size in [2], T in [Int]
    # for fct_type in ["vector of variables", "vector affine function"], array_size in [2, 3], sought_size in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(GlobalCardinalityVariableModel{T}())
    model = COIB.ClosedGlobalCardinalityVariable2GlobalCardinalityVariable{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.GlobalCardinalityVariable,
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Membership,
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.ClosedGlobalCardinalityVariable,
    )

    x_counts, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:sought_size])
    
    if T == Int
        x_array, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:array_size])
        x_sought, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:sought_size])
    elseif T == Float64
        x_array = MOI.add_variables(model, array_size)
        x_sought = MOI.add_variables(model, sought_size)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_array..., x_counts..., x_sought...])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_array..., x_counts..., x_sought...]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.ClosedGlobalCardinalityVariable(array_size, sought_size))

    for i in 1:array_size
        @test MOI.is_valid(model, x_array[i])
    end
    for i in 1:sought_size
        @test MOI.is_valid(model, x_counts[i])
        @test MOI.is_valid(model, x_sought[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.ClosedGlobalCardinalityVariable}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.ClosedGlobalCardinalityVariable) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.Membership),
            (MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Membership}()) == array_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable}()) == 1
        
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Membership}()) == bridge.cons_domain
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable}()) == [bridge.con_gcv]
    end

    @testset "Membership" begin
        @test length(bridge.cons_domain) == array_size
        for i in 1:array_size
            @test MOI.is_valid(model, bridge.cons_domain[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_domain[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_domain[i]) == CP.Membership(sought_size)

            @test length(f.terms) == 1 + sought_size

            @test f.terms[1].output_index == 1
            @test f.terms[1].scalar_term.coefficient === one(T)
            @test f.terms[1].scalar_term.variable_index === x_array[i]

            for j in 1:sought_size
                @test f.terms[1 + j].output_index == 1 + j
                @test f.terms[1 + j].scalar_term.coefficient === one(T)
                @test f.terms[1 + j].scalar_term.variable_index === x_sought[j]
            end
        end
    end

    @testset "Global cardinality" begin
        @test MOI.is_valid(model, bridge.con_gcv)
        f = MOIU.canonical(MOI.get(model, MOI.ConstraintFunction(), bridge.con_gcv))
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_gcv) == CP.GlobalCardinalityVariable(array_size, sought_size)

        # f == fct, in principle, with the exception that the bridge always 
        # uses a VectorAffineFunction, even if the input is a VectorOfVariables.
        @test length(f.terms) == array_size + 2 * sought_size
        @test f.constants == zeros(T, array_size + 2 * sought_size)

        for i in 1:(array_size + 2 * sought_size)
            t = f.terms[i]
            @test t.output_index == i
            @test t.scalar_term.coefficient === one(T)

            if 1 <= i <= array_size
                @test t.scalar_term.variable_index == x_array[i]
            elseif array_size + 1 <= i <= array_size + sought_size
                @test t.scalar_term.variable_index == x_counts[i - array_size]
            else
                @test t.scalar_term.variable_index == x_sought[i - array_size - sought_size]
            end
        end
    end
end
