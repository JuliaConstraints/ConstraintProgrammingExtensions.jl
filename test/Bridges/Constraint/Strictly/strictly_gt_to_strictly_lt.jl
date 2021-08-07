@testset "StrictlyGreaterThan2StrictlyLessThan: $(T)" for T in [Int, Float64]
    mock = MOIU.MockOptimizer(StrictlyLessThanMILPModel{T}())
    model = COIB.StrictlyGreaterThan2StrictlyLessThan{T}(mock)

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
        CP.Strictly{MOI.GreaterThan{T}, T},
    )

    if T == Int
        x, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x = MOI.add_variable(model)
    end

    fct = one(T) * MOI.SingleVariable(x)
    c = MOI.add_constraint(model, fct, CP.Strictly(MOI.GreaterThan(one(T))))

    @test MOI.is_valid(model, x)
    @test MOI.is_valid(model, c)

    bridge = first(MOIBC.bridges(model))[2]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T}}()) == [bridge.con]
    end

    @testset "Constraint" begin
        @test MOI.is_valid(model, bridge.con)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con)
        @test length(f.terms) == 1
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con) == CP.Strictly(MOI.LessThan(-one(T)))

        t1 = f.terms[1]
        @test t1.coefficient === -one(T)
        @test t1.variable_index == x
    end
end
