@testset "ReificationGreaterThan2Indicator: $(fct_type), type $(T)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    mock = MOIU.MockOptimizer(IndicatorPseudoMILPModel{T}())
    model = COIB.ReificationGreaterThan2Indicator{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.GreaterThan{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Reification{MOI.GreaterThan{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.Reification{MOI.GreaterThan{T}},
    )

    x, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
    if T == Int
        y, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        y = MOI.add_variable(model)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x, y])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.VariableIndex.([x, y]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Reification(MOI.GreaterThan(one(T))))

    @test MOI.is_valid(model, x)
    @test MOI.is_valid(model, y)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Reification{MOI.GreaterThan{T}}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Reification{MOI.GreaterThan{T}}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}),
            (MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.LessThan{T}, T}}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.LessThan{T}, T}}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}}()) == [bridge.indic_true]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.LessThan{T}, T}}}()) == [bridge.indic_false]
    end

    @testset "Constraint: indicator if true" begin
        @test MOI.is_valid(model, bridge.indic_true)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.indic_true)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.indic_true) == MOI.Indicator{MOI.ACTIVATE_ON_ONE}(MOI.GreaterThan(one(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variabl == x

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variabl == y
    end

    @testset "Constraint: indicator if false" begin
        @test MOI.is_valid(model, bridge.indic_false)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.indic_false)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.indic_false) == MOI.Indicator{MOI.ACTIVATE_ON_ZERO}(CP.Strictly(MOI.LessThan(one(T))))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variabl == x

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variabl == y
    end
end
