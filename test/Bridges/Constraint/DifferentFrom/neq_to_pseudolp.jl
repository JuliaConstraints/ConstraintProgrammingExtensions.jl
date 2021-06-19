@testset "DifferentFrom2PseudoMILP: $(fct_type), $(T)" for fct_type in ["single variable", "scalar affine function"], T in [Int, Bool, Float64]
    base = if T == Int
        IntAbsoluteValuePseudoMILPModel{Int}()
    elseif T == Bool
        BoolAbsoluteValuePseudoMILPModel{Bool}()
    elseif T == Float64
        FloatAbsoluteValuePseudoMILPModel{Float64}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base)
    model = COIB.DifferentFrom2PseudoMILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        CP.Strictly{MOI.LessThan{T}, T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        CP.DifferentFrom{T},
    )

    if T == Int
        x, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Bool
        x, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
    elseif T == Float64
        x = MOI.add_variable(model)
    else
        @assert false
    end

    fct = if fct_type == "single variable"
        MOI.SingleVariable(x)
    elseif fct_type == "scalar affine function"
        MOI.ScalarAffineFunction(
            [MOI.ScalarAffineTerm(one(T), x)], 
            zero(T),
        )
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.DifferentFrom(zero(T)))

    @test MOI.is_valid(model, x)
    @test MOI.is_valid(model, c)

    bridge = if fct_type == "single variable"
        MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.SingleVariable, CP.DifferentFrom{T}}(x.value)]
    elseif fct_type == "scalar affine function"
        MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T}}(1)] # Why a 1 for this specific case? Usually, it's -1.
    else
        @assert false
    end

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.DifferentFrom{T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]

        if T == Int
            @test MOIB.added_constraint_types(typeof(bridge)) == [
                (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
                (MOI.SingleVariable, MOI.GreaterThan{T}),
            ]
        elseif T == Bool
            @test MOIB.added_constraint_types(typeof(bridge)) == [
                (MOI.ScalarAffineFunction{Bool}, MOI.EqualTo{Bool}),
            ]
        elseif T == Float64
            @test MOIB.added_constraint_types(typeof(bridge)) == [
                (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
                (MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{T}}),
            ]
        else
            @assert false
        end

        @test MOI.get(bridge, MOI.NumberOfVariables()) == ((T == Bool) ? 0 : 1)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}()) == ((T == Bool) ? 0 : 1)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}}}()) == ((T == Float64) ? 1 : 0)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == ((T == Int) ? 1 : 0)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == ((T == Bool) ? 1 : 0)

        if T != Bool
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}()) == [bridge.con_abs]
        end
        if T == Float64
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}}}()) == [bridge.con_abs_strictly]
        end
        if T == Int
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == [bridge.con_abs_gt]
        end
        if T == Bool
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.con_eq]
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
            @test t1.scalar_term.variable_index == x
        end
    end
    
    if T == Float64
        @testset "Strictly greater than" begin
            @test MOI.is_valid(model, bridge.con_abs)
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_abs_strictly)
            @test length(f.terms) == 1
            @test MOI.get(model, MOI.ConstraintSet(), bridge.con_abs_strictly) == CP.Strictly(MOI.GreaterThan(zero(T)))
            
            t1 = f.terms[1]
            @test t1.coefficient === one(T)
            @test t1.variable_index == bridge.var_abs
        end
    end
    
    if T == Int
        @testset "Greater than" begin
            @test MOI.is_valid(model, bridge.con_abs_gt)
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_abs_gt)
            @test f.variable == bridge.var_abs
            @test MOI.get(model, MOI.ConstraintSet(), bridge.con_abs_gt) == MOI.GreaterThan(one(T))
        end
    end
    
    if T == Bool
        @testset "EqualTo" begin
            @test MOI.is_valid(model, bridge.con_eq)
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_eq)
            @test length(f.terms) == 1
            @test MOI.get(model, MOI.ConstraintSet(), bridge.con_eq) == MOI.EqualTo(one(T))
            
            t1 = f.terms[1]
            @test t1.coefficient === one(T)
            @test t1.variable_index == x
        end
    end

    # con_eq::Union{Nothing, MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}, MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo{T}}}
end
