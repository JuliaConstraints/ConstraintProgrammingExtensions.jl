@testset "Strictly2LP: $(set_type), $(fct_type), $(T)" for set_type in [MOI.GreaterThan, MOI.LessThan], fct_type in ["single variable", "scalar affine function"], T in [Int, Float64]
    mock = MOIU.MockOptimizer(DifferentFromModel{T}())
    model = COIB.Strictly2LP{T}(mock)

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
        MOI.ScalarAffineFunction{T},
        CP.Strictly{MOI.GreaterThan{T}, T},
    )

    if T == Int
        x, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x = MOI.add_variable(model)
    end

    fct = if fct_type == "single variable"
        x
    elseif fct_type == "scalar affine function"
        MOI.ScalarAffineFunction(
            [MOI.ScalarAffineTerm(one(T), x)], 
            zero(T),
        )
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Strictly(set_type(zero(T))))

    @test MOI.is_valid(model, x)
    @test MOI.is_valid(model, c)

    bridge = first(MOIBC.bridges(model))[2]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VariableIndex, CP.Strictly{set_type, T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
            (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, set_type{T}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, set_type{T}}()) == [bridge.con]
    end

    @testset "Constraint" begin
        target_value = if T == Int
            if set_type == MOI.GreaterThan
                one(T)
            elseif set_type == MOI.LessThan
                -one(T)
            else
                @assert false
            end
        elseif T == Float64
            if set_type == MOI.GreaterThan
                COIB._STRICTLY_FLOAT_EPSILON
            elseif set_type == MOI.LessThan
                -COIB._STRICTLY_FLOAT_EPSILON
            else
                @assert false
            end
        else
            @assert false
        end

        @test MOI.is_valid(model, bridge.con)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con)
        @test length(f.terms) == 1
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con) == set_type(target_value)

        t1 = f.terms[1]
        @test t1.coefficient === one(T)
        @test t1.variabl == x
    end
end
