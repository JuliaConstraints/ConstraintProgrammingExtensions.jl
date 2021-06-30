@testset "ReifiedEqualTo2Indicator: $(fct_type), type $(T)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    base_model = if T == Int
        IntDifferentFromIndicatorMILPModel{Int}()
    elseif T == Float64
        FloatDifferentFromIndicatorMILPModel{Float64}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.ReifiedEqualTo2Indicator{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Reified{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.Reified{MOI.EqualTo{T}},
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
        MOIU.vectorize(MOI.SingleVariable.([x, y]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Reified(MOI.EqualTo(zero(T))))

    MOI.is_valid(model, x)
    MOI.is_valid(model, y)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Reified{MOI.EqualTo{T}}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Reified{MOI.EqualTo{T}}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}),
            (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}()) == [bridge.indic_true]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}}}()) == [bridge.indic_false]
    end

    @testset "Constraint: indicator if true" begin
        @test MOI.is_valid(model, bridge.indic_true)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.indic_true)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.indic_true) == MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo(zero(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable_index == x

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable_index == y
    end

    @testset "Constraint: indicator if false" begin
        @test MOI.is_valid(model, bridge.indic_false)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.indic_false)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.indic_false) == MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO}(CP.DifferentFrom(zero(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable_index == x

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable_index == y
    end
end
