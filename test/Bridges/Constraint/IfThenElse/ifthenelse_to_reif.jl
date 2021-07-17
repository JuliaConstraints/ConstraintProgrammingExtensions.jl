@testset "IfThenElse2Reification: $(fct_type), $(T)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    base_model = if T == Int
        IntReificationEqualToModel{T}()
    elseif T == Float64
        FloatReificationEqualToModel{T}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.IfThenElse2Reification{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Reification{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.IfThenElse{MOI.LessThan{T}, MOI.LessThan{T}, MOI.LessThan{T}},
    )
    
    if T == Int
        x_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
        x_2, _ = MOI.add_constrained_variable(model, MOI.Integer())
        x_3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x_1 = MOI.add_variable(model)
        x_2 = MOI.add_variable(model)
        x_3 = MOI.add_variable(model)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_1, x_2, x_3])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_1, x_2, x_3]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.IfThenElse(MOI.LessThan(one(T)), MOI.LessThan(zero(T)), MOI.LessThan(zero(T))))

    @test MOI.is_valid(model, x_1)
    @test MOI.is_valid(model, x_2)
    @test MOI.is_valid(model, x_3)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.IfThenElse}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.IfThenElse{MOI.LessThan{T}, MOI.LessThan{T}, MOI.LessThan{T}}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.SingleVariable, MOI.ZeroOne),
            (MOI.VectorAffineFunction{T}, CP.Reification),
            (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 3
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == 3
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Reification}()) == 3
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == 2

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == [bridge.var_condition, bridge.var_true, bridge.var_false]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}()) == [bridge.var_condition_bin, bridge.var_true_bin, bridge.var_false_bin]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Reification}()) == [bridge.con_reif_condition, bridge.con_reif_true, bridge.con_reif_false]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == [bridge.con_if, bridge.con_else]
    end

    @testset "Set of variables" begin
        @test MOI.is_valid(model, bridge.var_condition)
        @test MOI.is_valid(model, bridge.var_condition_bin)
        @test MOI.get(model, MOI.ConstraintFunction(), bridge.var_condition_bin).variable == bridge.var_condition
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_condition_bin) == MOI.ZeroOne()

        @test MOI.is_valid(model, bridge.var_true)
        @test MOI.is_valid(model, bridge.var_true_bin)
        @test MOI.get(model, MOI.ConstraintFunction(), bridge.var_true_bin).variable == bridge.var_true
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_true_bin) == MOI.ZeroOne()

        @test MOI.is_valid(model, bridge.var_false)
        @test MOI.is_valid(model, bridge.var_false_bin)
        @test MOI.get(model, MOI.ConstraintFunction(), bridge.var_false_bin).variable == bridge.var_false
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_false_bin) == MOI.ZeroOne()
    end

    @testset "Reification of the condition" begin
        @test MOI.is_valid(model, bridge.con_reif_condition)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_reif_condition)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_reif_condition) == CP.Reification(MOI.LessThan(one(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable_index == bridge.var_condition

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable_index == x_1
    end 

    @testset "Reification of the true constraint" begin
        @test MOI.is_valid(model, bridge.con_reif_true)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_reif_true)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_reif_true) == CP.Reification(MOI.LessThan(zero(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable_index == bridge.var_true

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable_index == x_2
    end 

    @testset "Reification of the false constraint" begin
        @test MOI.is_valid(model, bridge.con_reif_false)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_reif_false)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_reif_false) == CP.Reification(MOI.LessThan(zero(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable_index == bridge.var_false

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable_index == x_3
    end 

    @testset "If" begin
        @test MOI.is_valid(model, bridge.con_if)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_if)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_if) == MOI.GreaterThan(zero(T))

        t1 = f.terms[1]
        @test t1.coefficient === -one(T)
        @test t1.variable_index == bridge.var_condition

        t2 = f.terms[2]
        @test t2.coefficient === one(T)
        @test t2.variable_index == bridge.var_true
    end

    @testset "Else" begin
        @test MOI.is_valid(model, bridge.con_else)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_else)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_else) == MOI.GreaterThan(one(T))

        t1 = f.terms[1]
        @test t1.coefficient === one(T)
        @test t1.variable_index == bridge.var_condition

        t2 = f.terms[2]
        @test t2.coefficient === one(T)
        @test t2.variable_index == bridge.var_false
    end
end
    