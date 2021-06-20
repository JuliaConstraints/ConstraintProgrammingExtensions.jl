@testset "IndicatorDifferentFrom2PseudoMILP: $(fct_type), $(T), $(A)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Bool, Float64], A in [MOI.ACTIVATE_ON_ZERO, MOI.ACTIVATE_ON_ONE]
    base_model = if T == Int
        IntAbsoluteValueIndicatorPseudoMILPModel{Int}()
    elseif T == Bool
        BoolAbsoluteValueIndicatorPseudoMILPModel{Bool}()
    elseif T == Float64
        FloatAbsoluteValueIndicatorPseudoMILPModel{Float64}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = if A == MOI.ACTIVATE_ON_ZERO
        COIB.Indicator0DifferentFrom2PseudoMILP{T}(mock)
    elseif A == MOI.ACTIVATE_ON_ONE
        COIB.Indicator1DifferentFrom2PseudoMILP{T}(mock)
    end

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        MOI.IndicatorSet{A, MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        MOI.IndicatorSet{A, CP.DifferentFrom{T}},
    )

    x, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
    if T == Int
        y, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Bool
        y, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
    elseif T == Float64
        y = MOI.add_variable(model)
    else
        @assert false
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x, y])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x, y]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, MOI.IndicatorSet{A}(CP.DifferentFrom(zero(T))))

    @test MOI.is_valid(model, x)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T}}(1)] # Why a 1 for this specific case? Usually, it's -1.

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.DifferentFrom{T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]

        if T == Int
            @test MOIB.added_constraint_types(typeof(bridge)) == [
                (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
                (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{A, MOI.GreaterThan{T}}),
            ]
        elseif T == Bool
            @test MOIB.added_constraint_types(typeof(bridge)) == [
                (MOI.VectorAffineFunction{Bool}, MOI.IndicatorSet{A, MOI.EqualTo{Bool}}),
            ]
        elseif T == Float64
            @test MOIB.added_constraint_types(typeof(bridge)) == [
                (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
                (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{A, CP.Strictly{MOI.GreaterThan{T}}}),
            ]
        else
            @assert false
        end

        @test MOI.get(bridge, MOI.NumberOfVariables()) == ((T == Bool) ? 0 : 1)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}()) == ((T == Bool) ? 0 : 1)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{A, CP.Strictly{MOI.GreaterThan{T}}}}()) == ((T == Float64) ? 1 : 0)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{A, MOI.GreaterThan{T}}}()) == ((T == Int) ? 1 : 0)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{A, MOI.EqualTo{T}}}()) == ((T == Bool) ? 1 : 0)

        if T != Bool
            @test MOI.get(bridge, MOI.ListOfVariableIndices()) == [bridge.var_abs]
        end
        if T != Bool
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}()) == [bridge.con_abs]
        end
        if T == Float64
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{A, CP.Strictly{MOI.GreaterThan{T}}}}()) == [bridge.con_indic]
        end
        if T == Int
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{A, MOI.GreaterThan{T}}}()) == [bridge.con_indic]
        end
        if T == Bool
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{A, MOI.EqualTo{T}}}()) == [bridge.con_indic]
        end
    end

    if T != Bool
        @testset "Absolute value" begin
            @test MOI.is_valid(model, bridge.con_abs)
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_abs)
            @test length(f.terms) == 2
            @test MOI.get(model, MOI.ConstraintSet(), bridge.con_abs) == CP.AbsoluteValue()
            
            t1 = f.terms[1]
            @test t1.output_index == 1
            @test t1.scalar_term.coefficient === one(T)
            @test t1.scalar_term.variable_index == bridge.var_abs
            
            t1 = f.terms[2]
            @test t1.output_index == 2
            @test t1.scalar_term.coefficient === one(T)
            @test t1.scalar_term.variable_index == y
        end
    end
    
    if T == Float64
        @testset "Strictly greater than" begin
            @test MOI.is_valid(model, bridge.con_indic)
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_indic)
            @test length(f.terms) == 2
            @test MOI.get(model, MOI.ConstraintSet(), bridge.con_indic) == MOI.IndicatorSet{A}(CP.Strictly(MOI.GreaterThan(zero(T))))

            t1 = f.terms[1]
            @test t1.output_index == 1
            @test t1.scalar_term.coefficient == one(T)
            @test t1.scalar_term.variable_index == x

            t2 = f.terms[2]
            @test t2.output_index == 2
            @test t2.scalar_term.coefficient == one(T)
            @test t2.scalar_term.variable_index == bridge.var_abs
        end
    end
    
    if T == Int
        @testset "Greater than" begin
            @test MOI.is_valid(model, bridge.con_indic)
            @test MOI.get(model, MOI.ConstraintSet(), bridge.con_indic) == MOI.IndicatorSet{A}(MOI.GreaterThan(one(T)))
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_indic)
            @test length(f.terms) == 2

            t1 = f.terms[1]
            @test t1.output_index == 1
            @test t1.scalar_term.coefficient == one(T)
            @test t1.scalar_term.variable_index == x

            t2 = f.terms[2]
            @test t2.output_index == 2
            @test t2.scalar_term.coefficient == one(T)
            @test t2.scalar_term.variable_index == bridge.var_abs
        end
    end
    
    if T == Bool
        @testset "EqualTo" begin
            @test MOI.is_valid(model, bridge.con_indic)
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_indic)
            @test length(f.terms) == 2
            @test MOI.get(model, MOI.ConstraintSet(), bridge.con_indic) == MOI.IndicatorSet{A}(MOI.EqualTo(one(T)))
            
            t1 = f.terms[1]
            @test t1.output_index == 1
            @test t1.scalar_term.coefficient == one(T)
            @test t1.scalar_term.variable_index == x

            t2 = f.terms[2]
            @test t2.output_index == 2
            @test t2.scalar_term.coefficient == one(T)
            @test t2.scalar_term.variable_index == y
        end
    end
end
