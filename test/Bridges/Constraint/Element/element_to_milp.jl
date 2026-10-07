@testset "Element2MILP: $(fct_type), dimension $(dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.Element2MILP{T}(mock)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Element{T},
    )

    x_index, _ = MOI.add_constrained_variable(model, MOI.Integer())
    if T == Int
        x_value, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x_value = MOI.add_variable(model)
    end
    values = T.(collect(T(4) .+ (1:dim)))

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_value, x_index])
    elseif fct_type == "vector affine function"
        MOIU.vectorize([x_value, x_index])
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Element(values))

    @test MOI.is_valid(model, x_value)
    @test MOI.is_valid(model, x_index)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Element}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Element) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VariableIndex, MOI.ZeroOne}()) == dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 3

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == bridge.vars
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.ZeroOne}()) == bridge.vars_bin
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.con_unary, bridge.con_choose_one, bridge.con_value]
    end

    @testset "Set of variables" begin
        @test length(bridge.vars) == dim
        for i in 1:dim
            @test MOI.is_valid(model, bridge.vars[i])
            @test MOI.is_valid(model, bridge.vars_bin[i])
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_bin[i]) == bridge.vars[i]
            @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_bin[i]) == MOI.ZeroOne()
        end
    end

    @testset "Unary decomposition of the index" begin
        @test MOI.is_valid(model, bridge.con_unary)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_unary)
        @test length(f.terms) == dim + 1
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_unary) == MOI.EqualTo(zero(T))

        t = f.terms[1]
        @test t.coefficient === -one(T)
        @test t.variable == x_index

        for i in 1:dim
            t = f.terms[i + 1]
            @test t.coefficient === T(i)
            @test t.variable == bridge.vars[i]
        end
    end

    @testset "Unicity of the unary decomposition" begin
        @test MOI.is_valid(model, bridge.con_choose_one)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_choose_one)
        @test length(f.terms) == dim
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_choose_one) == MOI.EqualTo(one(T))

        for i in 1:dim
            t = f.terms[i]
            @test t.coefficient === one(T)
            @test t.variable == bridge.vars[i]
        end
    end

    @testset "Value at the index" begin
        @test MOI.is_valid(model, bridge.con_value)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_value)
        @test length(f.terms) == dim + 1
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_value) == MOI.EqualTo(zero(T))

        t = f.terms[1]
        @test t.coefficient === -one(T)
        @test t.variable == x_value

        for i in 1:dim
            t = f.terms[i + 1]
            @test t.coefficient === values[i]
            @test t.variable == bridge.vars[i]
        end
    end
end
