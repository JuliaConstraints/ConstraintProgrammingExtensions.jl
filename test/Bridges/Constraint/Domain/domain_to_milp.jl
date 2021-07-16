@testset "Domain2MILP: $(fct_type), dimension $(dim), $(n_values) values, $(T)" for fct_type in ["single variable"], dim in [2], n_values in [3], T in [Int]
    # for fct_type in ["single variable", "scalar affine function"], dim in [2, 3], n_values in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.Domain2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    end
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
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
        MOI.SingleVariable,
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
        MOI.SingleVariable(x)
    elseif fct_type == "scalar affine function"
        one(T) * MOI.SingleVariable(x)
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Domain(x_values))

    @test MOI.is_valid(model, x)
    @test MOI.is_valid(model, c)

    bridge = first(MOIBC.bridges(model))[2]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.SingleVariable, CP.Domain{T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.SingleVariable, MOI.ZeroOne),
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == n_values
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == n_values
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 2

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}()) == bridge.vars_bin
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.con_choose_one, bridge.con_value]
    end

    @testset "New variables" begin
        @test length(bridge.vars) == n_values
        @test length(bridge.vars_bin) == n_values

        for i in 1:n_values
            @test MOI.is_valid(model, bridge.vars[i])
            @test MOI.is_valid(model, bridge.vars_bin[i])
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_bin[i]) == MOI.SingleVariable(bridge.vars[i])
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
            @test t.variable_index == bridge.vars[i]
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
        @test t1.variable_index == x

        for j in 1:n_values
            t = f.terms[1 + j]
            @test t.coefficient === -x_vector[j]
            @test t.variable_index == bridge.vars[j]
        end
    end
end
