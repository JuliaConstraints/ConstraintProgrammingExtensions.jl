@testset "GlobalCardinality2GlobalCardinalityVariable: $(fct_type), $(array_size) items, $(sought_size) sought items, $(T)" for fct_type in ["vector of variables", "vector affine function"], array_size in [2, 3], sought_size in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(GlobalCardinalityVariableModel{T}())
    model = COIB.GlobalCardinality2GlobalCardinalityVariable{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.GlobalCardinalityVariable,
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
        if T == Int
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.Integer,)]
            @test MOIB.added_constraint_types(typeof(bridge)) == [
                (MOI.SingleVariable, MOI.Integer),
                (MOI.SingleVariable, MOI.EqualTo{T}),
                (MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable),
            ]
        elseif T == Float64
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
            @test MOIB.added_constraint_types(typeof(bridge)) == [
                (MOI.SingleVariable, MOI.EqualTo{T}),
                (MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable),
            ]
        else
            @assert false
        end

        @test MOI.get(bridge, MOI.NumberOfVariables()) == sought_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}()) == ((T == Int) ? sought_size : 0)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.EqualTo{T}}()) == sought_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable}()) == 1

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == bridge.vars
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.Integer}()) == bridge.vars_int
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.EqualTo{T}}()) == bridge.cons_eq
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable}()) == [bridge.con_gcv]
    end

    @testset "Variables" begin
        @test length(bridge.vars) == sought_size
        for i in 1:sought_size
            @test MOI.is_valid(model, bridge.vars[i])
                
            if T == Int
                @test MOI.is_valid(model, bridge.vars_int[i])
                @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_int[i]) == MOI.SingleVariable(bridge.vars[i])
                @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_int[i]) == MOI.Integer()
            end
        end
    end

    @testset "Sought array" begin
        @test length(bridge.cons_eq) == sought_size
        for i in 1:sought_size
            @test MOI.is_valid(model, bridge.cons_eq[i])
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.cons_eq[i]) == MOI.SingleVariable(bridge.vars[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_eq[i]) == MOI.EqualTo(sought_values[i])
        end
    end

    @testset "Global cardinality" begin
        @test MOI.is_valid(model, bridge.con_gcv)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_gcv)
        @test length(f.terms) == array_size + 2 * sought_size
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_gcv) == CP.GlobalCardinalityVariable(array_size, sought_size)

        for i in 1:array_size
            t = f.terms[i]
            @test t.output_index == i
            @test t.scalar_term.coefficient === one(T)
            @test t.scalar_term.variable_index === x_array[i]
        end

        for i in 1:sought_size
            t = f.terms[array_size + i]
            @test t.output_index == array_size + i
            @test t.scalar_term.coefficient === one(T)
            @test t.scalar_term.variable_index === x_counts[i]
        end

        for i in 1:sought_size
            t = f.terms[array_size + sought_size + i]
            @test t.output_index == array_size + sought_size + i
            @test t.scalar_term.coefficient === one(T)
            @test t.scalar_term.variable_index === bridge.vars[i]
        end
    end
end
