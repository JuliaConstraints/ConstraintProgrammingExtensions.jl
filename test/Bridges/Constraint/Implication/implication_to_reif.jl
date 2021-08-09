@testset "Implication2Reification: $(fct_type), $(T)" for fct_type in ["vector of variables", "vector affine function"], T in [Int, Float64]
    base_model = if T == Int
        IntReificationEqualToModel{T}()
    elseif T == Float64
        FloatReificationEqualToModel{T}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.Implication2Reification{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Reification{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Implication{MOI.LessThan{T}, MOI.LessThan{T}},
    )
    
    if T == Int
        x_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
        x_2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T == Float64
        x_1 = MOI.add_variable(model)
        x_2 = MOI.add_variable(model)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_1, x_2])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_1, x_2]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Implication(MOI.LessThan(one(T)), MOI.LessThan(zero(T))))

    @test MOI.is_valid(model, x_1)
    @test MOI.is_valid(model, x_2)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Implication}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Reification) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.Reification),
            (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Reification}()) == 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == 1

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == [bridge.var_antecedent, bridge.var_consequent]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}()) == [bridge.var_antecedent_bin, bridge.var_consequent_bin]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Reification}()) == [bridge.con_reif_antecedent, bridge.con_reif_consequent]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == [bridge.con_implication]
    end

    @testset "Set of variables" begin
        @test MOI.is_valid(model, bridge.var_antecedent)
        @test MOI.is_valid(model, bridge.var_antecedent_bin)
        @test MOI.get(model, MOI.ConstraintFunction(), bridge.var_antecedent_bin).variable == bridge.var_antecedent
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_antecedent_bin) == MOI.ZeroOne()

        @test MOI.is_valid(model, bridge.var_consequent)
        @test MOI.is_valid(model, bridge.var_consequent_bin)
        @test MOI.get(model, MOI.ConstraintFunction(), bridge.var_consequent_bin).variable == bridge.var_consequent
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_consequent_bin) == MOI.ZeroOne()
    end

    @testset "Reification of the antecedent" begin
        @test MOI.is_valid(model, bridge.con_reif_antecedent)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_reif_antecedent)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_reif_antecedent) == CP.Reification(MOI.LessThan(one(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable_index == bridge.var_antecedent

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable_index == x_1
    end 

    @testset "Reification of the consequent" begin
        @test MOI.is_valid(model, bridge.con_reif_consequent)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_reif_consequent)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_reif_consequent) == CP.Reification(MOI.LessThan(zero(T)))

        t1 = f.terms[1]
        @test t1.output_index == 1
        @test t1.scalar_term.coefficient === one(T)
        @test t1.scalar_term.variable_index == bridge.var_consequent

        t2 = f.terms[2]
        @test t2.output_index == 2
        @test t2.scalar_term.coefficient === one(T)
        @test t2.scalar_term.variable_index == x_2
    end 

    @testset "Implication" begin
        @test MOI.is_valid(model, bridge.con_implication)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_implication)
        @test length(f.terms) == 2
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_implication) == MOI.GreaterThan(zero(T))

        t1 = f.terms[1]
        @test t1.coefficient === -one(T)
        @test t1.variable_index == bridge.var_antecedent

        t2 = f.terms[2]
        @test t2.coefficient === one(T)
        @test t2.variable_index == bridge.var_consequent
    end
end
    