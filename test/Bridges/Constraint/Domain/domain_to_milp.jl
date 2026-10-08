@testset "Domain2MILP: $(fct_type), dimension $(dim), $(n_values) values, $(T)" for fct_type in ["single variable", "scalar affine function"], dim in [2, 3], n_values in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.Domain2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    end
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        CP.Domain{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VariableIndex,
        CP.Domain{T},
    )

    if T == Int
        x, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x = MOI.add_variable(model)
    end
    x_values = Set(
        T(i)
        for i in 1:n_values
    )
    x_vector = collect(x_values) # Use collect() to get the same order as in the bridge.

    fct = if fct_type == "single variable"
        x
    elseif fct_type == "scalar affine function"
        one(T) * x
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Domain(x_values))

    @test MOI.is_valid(model, x)
    @test MOI.is_valid(model, c)

    bridge = first(MOIBC.bridges(model))[2]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VariableIndex, CP.Domain{T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == n_values
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VariableIndex, MOI.ZeroOne}()) == n_values
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 2

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == bridge.vars
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.ZeroOne}()) == bridge.vars_bin
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.con_choose_one, bridge.con_value]
    end

    @testset "New variables" begin
        @test length(bridge.vars) == n_values
        @test length(bridge.vars_bin) == n_values

        for i in 1:n_values
            @test MOI.is_valid(model, bridge.vars[i])
            @test MOI.is_valid(model, bridge.vars_bin[i])
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_bin[i]) == bridge.vars[i]
            @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_bin[i]) == MOI.ZeroOne()
        end
    end

    @testset "Choose one" begin
        @test MOI.is_valid(model, bridge.con_choose_one)
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_choose_one) == MOI.EqualTo(one(T))

        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_choose_one)
        @test length(f.terms) == n_values
        @test f.constant === zero(T)

        for i in 1:n_values
            t = f.terms[i]
            @test t.coefficient === one(T)
            @test t.variable == bridge.vars[i]
        end
    end

    @testset "Value" begin
        @test MOI.is_valid(model, bridge.con_value)
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_value) == MOI.EqualTo(zero(T))

        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_value)
        @test length(f.terms) == 1 + n_values
        @test f.constant === zero(T)

        t1 = f.terms[1]
        @test t1.coefficient === one(T)
        @test t1.variable == x

        for j in 1:n_values
            t = f.terms[1 + j]
            @test t.coefficient === -x_vector[j]
            @test t.variable == bridge.vars[j]
        end
    end
end

@testset "Domain affine projection and owned buffers: $T" for T in (Int, Float64)
    model = MOIU.Model{T}()
    x, y = MOI.add_variables(model, 2)
    f = MOI.ScalarAffineFunction([
        MOI.ScalarAffineTerm(T(2), x), MOI.ScalarAffineTerm(T(-1), y),
        MOI.ScalarAffineTerm(T(1), x)], T(3))
    original = copy(f)
    domain = CP.Domain(Set(T[-3, 0, 6]))
    bridge = MOIBC.bridge_constraint(COIB.Domain2MILPBridge{T}, model, f, domain)
    @test f.terms == original.terms && f.constant == original.constant
    value_equation = MOI.get(model, MOI.ConstraintFunction(), bridge.con_value)
    choose_equation = MOI.get(model, MOI.ConstraintFunction(), bridge.con_choose_one)
    # Check the projection independently, including repeated source terms and a
    # nonzero constant, for every binary selector and several source assignments.
    ordered = collect(domain.values)
    values = zeros(T, MOI.get(model, MOI.NumberOfVariables()))
    for a in -2:2, b in -2:2, selected in 1:length(ordered)
        fill!(values, zero(T))
        values[x.value], values[y.value] = T(a), T(b)
        values[bridge.vars[selected].value] = one(T)
        evaluate(g) = MOIU.eval_variables(v -> values[v.value], g)
        @test evaluate(choose_equation) == one(T)
        @test iszero(evaluate(value_equation)) == (3a - b + 3 == ordered[selected])
    end
    returned = MOI.get(bridge, MOI.ListOfVariableIndices())
    empty!(returned)
    @test length(bridge.vars) == 3
    value_equation.terms[1] = MOI.ScalarAffineTerm(T(99), x)
    @test f.terms == original.terms && f.constant == original.constant
end
