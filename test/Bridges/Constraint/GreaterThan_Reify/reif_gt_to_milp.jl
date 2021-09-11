@testset "ReificationGreaterThan2MILP: $(fct_type), type $(T)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.ReificationGreaterThan2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
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
        MOIU.vectorize(MOI.SingleVariable.([x, y]))
    else
        @assert false
    end

    @test_throws AssertionError MOI.add_constraint(model, fct, CP.Reification(MOI.GreaterThan(zero(T))))
    
    MOI.add_constraint(model, y, MOI.LessThan(5 * one(T)))
    MOI.add_constraint(model, y, MOI.GreaterThan(2 * one(T)))

    c = MOI.add_constraint(model, fct, CP.Reification(MOI.GreaterThan(zero(T))))

    @test MOI.is_valid(model, x)
    @test MOI.is_valid(model, y)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Reification{MOI.GreaterThan{T}}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Reification{MOI.GreaterThan{T}}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, MOI.GreaterThan{T}),
            (MOI.VectorAffineFunction{T}, MOI.LessThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == 1
        
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == [bridge.con_bigm]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == [bridge.con_smallm]
    end

    @testset "Constraint: big-M" begin
        @test MOI.is_valid(model, bridge.con_bigm)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_bigm)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_bigm) == MOI.GreaterThan(zero(T))

        t1 = f.terms[1]
        @test t1.coefficient === 5 * one(T)
        @test t1.variabl == x

        t2 = f.terms[2]
        @test t2.coefficient === one(T)
        @test t2.variabl == y
    end

    @testset "Constraint: small-M" begin
        @test MOI.is_valid(model, bridge.con_smallm)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_smallm)
        @test length(f.terms) == 2

        ub = if T == Int
            -one(T)
        elseif T == Float64
            -1.0e-5
        else
            @assert false
        end
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_smallm) == MOI.LessThan(ub)

        t1 = f.terms[1]
        @test t1.coefficient === -5 * one(T)
        @test t1.variabl == x

        t2 = f.terms[2]
        @test t2.coefficient === one(T)
        @test t2.variabl == y
    end
end
