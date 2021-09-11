@testset "Conjunction2Reification: $(fct_type), $(array_size) items, $(T)" for fct_type in ["vector of variables", "vector affine function"], array_size in [2, 4], T in [Int, Float64]
    base_model = if T == Int
        IntReificationEqualToModel{T}()
    elseif T == Float64
        FloatReificationEqualToModel{T}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.Conjunction2Reification{T}(mock)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Reification{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Conjunction{NTuple{array_size, MOI.LessThan{T}}},
    )
    
    if T == Int
        x_array, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:array_size])
    elseif T == Float64
        x_array = MOI.add_variables(model, array_size)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables(x_array)
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.VariableIndex.(x_array))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, 
        CP.Conjunction(tuple(collect(MOI.LessThan(one(T)) for i in 1:array_size)...))
    )

    for i in 1:array_size
        @test MOI.is_valid(model, x_array[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Reification}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Reification) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.Reification),
            (MOI.VariableIndex, MOI.EqualTo{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VariableIndex, MOI.ZeroOne}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Reification}()) == array_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VariableIndex, MOI.EqualTo{T}}()) == 1

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == [bridge.var]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.ZeroOne}()) == [bridge.var_bin]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Reification}()) == bridge.cons_reif
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.EqualTo{T}}()) == [bridge.con_conjunction]
    end

    @testset "Set of variables" begin
        @test MOI.is_valid(model, bridge.var)
        @test MOI.is_valid(model, bridge.var_bin)
        @test MOI.get(model, MOI.ConstraintFunction(), bridge.var_bin).variable == bridge.var
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_bin) == MOI.ZeroOne()
    end

    @testset "Reification" begin
        @test length(bridge.cons_reif) == array_size
        for i in 1:array_size
            @test MOI.is_valid(model, bridge.cons_reif[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_reif[i])
            @test length(f.terms) == 2
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_reif[i]) == CP.Reification(MOI.LessThan(one(T)))

            t1 = f.terms[1]
            @test t1.output_index == 1
            @test t1.scalar_term.coefficient === one(T)
            @test t1.scalar_term.variable == bridge.var

            t2 = f.terms[2]
            @test t2.output_index == 2
            @test t2.scalar_term.coefficient === one(T)
            @test t2.scalar_term.variable == x_array[i]
        end
    end 

    @testset "Sum" begin
        @test MOI.is_valid(model, bridge.con_conjunction)
        @test MOI.get(model, MOI.ConstraintFunction(), bridge.con_conjunction) == bridge.var
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_conjunction) == MOI.EqualTo(one(T))
    end
end
    