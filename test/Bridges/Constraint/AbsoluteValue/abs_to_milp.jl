@testset "AbsoluteValue2MILPBridge: $(fct_type), $(T)" for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.AbsoluteValue2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.AbsoluteValue,
    )

    if T == Int
        x, _ = MOI.add_constrained_variable(model, MOI.Integer())
        x_abs, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x = MOI.add_variable(model)
        x_abs = MOI.add_variable(model)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_abs, x])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_abs, x]))
    else
        @assert false
    end

    @test_throws AssertionError MOI.add_constraint(model, fct, CP.AbsoluteValue())
    
    MOI.add_constraint(model, x, MOI.LessThan(5 * one(T)))
    MOI.add_constraint(model, x, MOI.GreaterThan(2 * one(T)))

    c = MOI.add_constraint(model, fct, CP.AbsoluteValue())

    MOI.is_valid(model, x)
    MOI.is_valid(model, x_abs)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.AbsoluteValue}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.AbsoluteValue) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne), (MOI.GreaterThan{T})]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.SingleVariable, MOI.ZeroOne),
            (MOI.SingleVariable, MOI.GreaterThan{T}),
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 3
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.GreaterThan{T}}()) == 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == 2

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == [bridge.var_bin, bridge.var_pos, bridge.var_neg]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}()) == [bridge.var_bin_con]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.GreaterThan{T}}()) == [bridge.var_pos_con, bridge.var_neg_con]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.con_original_var, bridge.con_abs_var]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == [bridge.con_pos_var_big_m, bridge.con_neg_var_big_m]
    end

    @testset "Set of variables" begin
        @test MOI.is_valid(model, bridge.var_bin)
        @test MOI.is_valid(model, bridge.var_pos)
        @test MOI.is_valid(model, bridge.var_neg)
    end

    @testset "Set of constraints" begin
        @test MOI.is_valid(model, bridge.var_bin_con)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.var_bin_con)
        @test f.variable == bridge.var_bin
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_bin_con) == MOI.ZeroOne()

        @test MOI.is_valid(model, bridge.var_pos_con)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.var_pos_con)
        @test f.variable == bridge.var_pos
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_pos_con) == MOI.GreaterThan(zero(T))

        @test MOI.is_valid(model, bridge.var_neg_con)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.var_neg_con)
        @test f.variable == bridge.var_neg
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_neg_con) == MOI.GreaterThan(zero(T))

        @test MOI.is_valid(model, bridge.con_original_var)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_original_var)
        @test f.constant === zero(T)
        @test length(f.terms) == 3
        t1 = f.terms[1]
        @test t1.coefficient === one(T)
        @test t1.variable_index == x
        t2 = f.terms[2]
        @test t2.coefficient === -one(T)
        @test t2.variable_index == bridge.var_pos
        t3 = f.terms[3]
        @test t3.coefficient === one(T)
        @test t3.variable_index == bridge.var_neg
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_original_var) == MOI.EqualTo(zero(T))

        @test MOI.is_valid(model, bridge.con_abs_var)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_abs_var)
        @test f.constant === zero(T)
        @test length(f.terms) == 3
        t1 = f.terms[1]
        @test t1.coefficient === one(T)
        @test t1.variable_index == x_abs
        t2 = f.terms[2]
        @test t2.coefficient === -one(T)
        @test t2.variable_index == bridge.var_pos
        t3 = f.terms[3]
        @test t3.coefficient === -one(T)
        @test t3.variable_index == bridge.var_neg
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_abs_var) == MOI.EqualTo(zero(T))

        @test MOI.is_valid(model, bridge.con_pos_var_big_m)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_pos_var_big_m)
        @test abs(f.constant) === zero(T)
        @test length(f.terms) == 2
        t1 = f.terms[1]
        @test t1.coefficient === -5 * one(T)
        @test t1.variable_index == bridge.var_bin
        t2 = f.terms[2]
        @test t2.coefficient === one(T)
        @test t2.variable_index == bridge.var_pos
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_pos_var_big_m) == MOI.LessThan(zero(T))

        @test MOI.is_valid(model, bridge.con_neg_var_big_m)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_neg_var_big_m)
        @test abs(f.constant) === 5 * one(T)
        @test length(f.terms) == 2
        t1 = f.terms[1]
        @test t1.coefficient === 5 * one(T)
        @test t1.variable_index == bridge.var_bin
        t2 = f.terms[2]
        @test t2.coefficient === one(T)
        @test t2.variable_index == bridge.var_neg
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_neg_var_big_m) == MOI.LessThan(zero(T))
    end
end
