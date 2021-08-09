@testset "IfThenElse2Implication: $(fct_type), $(T)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    mock = MOIU.MockOptimizer(ImplicationModel{T}())
    model = COIB.IfThenElse2Implication{T}(mock)

    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Implication{MOI.LessThan{T}, MOI.LessThan{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.IfThenElse{MOI.LessThan{T}, MOI.LessThan{T}, MOI.LessThan{T}},
    )
    
    if T == Int
        x_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
        x_2, _ = MOI.add_constrained_variable(model, MOI.Integer())
        x_3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x_1 = MOI.add_variable(model)
        x_2 = MOI.add_variable(model)
        x_3 = MOI.add_variable(model)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_1, x_2, x_3])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_1, x_2, x_3]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.IfThenElse(MOI.LessThan(one(T)), MOI.LessThan(zero(T)), MOI.LessThan(zero(T))))

    @test MOI.is_valid(model, x_1)
    @test MOI.is_valid(model, x_2)
    @test MOI.is_valid(model, x_3)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.IfThenElse}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.IfThenElse{MOI.LessThan{T}, MOI.LessThan{T}, MOI.LessThan{T}}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.Implication),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Implication}()) == 2

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Implication}()) == [bridge.con_if, bridge.con_else]
    end

    @testset "If" begin
        @test MOI.is_valid(model, bridge.con_if)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_if)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_if) == CP.Implication(MOI.LessThan(one(T)), MOI.LessThan(zero(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable_index == x_1

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable_index == x_2
    end

    @testset "Else" begin
        @test MOI.is_valid(model, bridge.con_else)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_else)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_else) == CP.Implication(MOI.LessThan(one(T)), MOI.LessThan(zero(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable_index == x_1

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable_index == x_3
    end
end
    