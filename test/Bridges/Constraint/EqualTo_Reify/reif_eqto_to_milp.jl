@testset "ReificationEqualTo2MILP: $(fct_type), type $(T)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    mock = MOIU.MockOptimizer(AbsoluteValueModel{T}())
    model = COIB.ReificationEqualTo2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.AbsoluteValue,
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Reification{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.Reification{MOI.EqualTo{T}},
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

    @test_throws AssertionError MOI.add_constraint(model, fct, CP.Reification(MOI.EqualTo(zero(T))))
    
    MOI.add_constraint(model, y, MOI.LessThan(5 * one(T)))
    MOI.add_constraint(model, y, MOI.GreaterThan(2 * one(T)))

    c = MOI.add_constraint(model, fct, CP.Reification(MOI.EqualTo(zero(T))))

    @test MOI.is_valid(model, x)
    @test MOI.is_valid(model, y)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Reification{MOI.EqualTo{T}}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Reification{MOI.EqualTo{T}}) == typeof(bridge)
        if T == Int
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.Integer,)]
        elseif T == Float64
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        else
            @assert false
        end
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
            (MOI.VectorAffineFunction{T}, MOI.LessThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VariableIndex, MOI.Integer}()) == ((T == Int) ? 1 : 0)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == 2
        
        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == [bridge.var_abs]
        if T == Int
            @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.Integer}()) == [bridge.var_abs_int]
        end
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}()) == [bridge.con_abs]
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}())) == Set([bridge.con_bigm, bridge.con_smallm])
    end

    @testset "Constraint: absolute value" begin
        @test MOI.is_valid(model, bridge.con_abs)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_abs)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_abs) == CP.AbsoluteValue()

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable == bridge.var_abs

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable == y
    end

    @testset "Constraint: big-M" begin
        @test MOI.is_valid(model, bridge.con_bigm)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_bigm)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_bigm) == MOI.LessThan(zero(T))

        t1 = f.terms[1]
        @test t1.coefficient === 5 * one(T)
        @test t1.variable == x

        t2 = f.terms[2]
        @test t2.coefficient === one(T)
        @test t2.variable == bridge.var_abs
    end

    @testset "Constraint: small-M" begin
        @test MOI.is_valid(model, bridge.con_smallm)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_smallm)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_smallm) == MOI.LessThan(zero(T))

        t1 = f.terms[1]
        @test t1.coefficient === one(T)
        @test t1.variable == x

        smallm = if T == Int
            -1
        elseif T == Float64
            -100_000.0
        else
            @assert false
        end

        t2 = f.terms[2]
        @test t2.coefficient ≈ smallm
        @test t2.variable == bridge.var_abs
    end
end
