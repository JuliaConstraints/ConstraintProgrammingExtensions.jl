@testset "Disjunction2Reification: $(fct_type), $(array_size) items, $(T)" for fct_type in ["vector of variables", "vector affine function"], array_size in [2, 4], T in [Int, Float64]
    base_model = if T == Int
        IntReificationEqualToModel{T}()
    elseif T == Float64
        FloatReificationEqualToModel{T}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.Disjunction2Reification{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Reification{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Disjunction{NTuple{array_size, MOI.LessThan{T}}},
    )
    
    if T == Int
        x_array, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:array_size])
    elseif T == Float64
        x_array = MOI.add_variables(model, array_size)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables(x_array)
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.(x_array))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, 
        CP.Disjunction(tuple(collect(MOI.LessThan(one(T)) for i in 1:array_size)...))
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
            (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == array_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == array_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Reification}()) == array_size
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == 1

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == bridge.vars
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}()) == bridge.vars_bin
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Reification}()) == bridge.cons_reif
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == [bridge.con_disjunction]
    end

    @testset "Set of variables" begin
        @test length(bridge.vars) == array_size
        @test length(bridge.vars_bin) == array_size
        for i in 1:array_size
            @test MOI.is_valid(model, bridge.vars[i])
            @test MOI.is_valid(model, bridge.vars_bin[i])
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_bin[i]).variable == bridge.vars[i]
            @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_bin[i]) == MOI.ZeroOne()
        end
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
            @test t1.scalar_term.variabl == bridge.vars[i]

            t2 = f.terms[2]
            @test t2.output_index == 2
            @test t2.scalar_term.coefficient === one(T)
            @test t2.scalar_term.variabl == x_array[i]
        end
    end 

    @testset "Sum" begin
        @test MOI.is_valid(model, bridge.con_disjunction)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_disjunction)
        @test length(f.terms) == array_size
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_disjunction) == MOI.GreaterThan(one(T))

        for i in 1:array_size
            t = f.terms[i]
            @test t.coefficient === one(T)
            @test t.variabl == bridge.vars[i]
        end
    end
end
    