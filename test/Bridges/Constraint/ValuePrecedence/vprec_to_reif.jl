@testset "ValuePrecedence2Reification: $(fct_type), dimension $(dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], T in [Int, Float64]
    base_model = if T == Int
        IntReificationEqualToModel{T}()
    elseif T == Float64
        FloatReificationEqualToModel{T}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.ValuePrecedence2Reification{T}(mock)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T}, 
        CP.Reification{MOI.EqualTo{T}},
    )
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T}, 
        MOI.LessThan{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.ValuePrecedence{T},
    )

    if T == Int
        x, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:dim])
    elseif T == Float64
        x = MOI.add_variables(model, dim)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables(x)
    elseif fct_type == "vector affine function"
        MOIU.vectorize(x)
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.ValuePrecedence(T(2), T(4), dim))

    for i in 1:dim
        @test MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = first(MOIBC.bridges(model))[2]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VariableIndex, CP.SymmetricAllDifferent) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}),
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 2 * (dim - 1)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VariableIndex, MOI.ZeroOne}()) == 2 * (dim - 1)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}}()) == 2 * (dim - 1)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == dim - 1

        @test Set(MOI.get(bridge, MOI.ListOfVariableIndices())) == Set([bridge.vars_reif_precv..., bridge.vars_reif_value...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.ZeroOne}())) == Set([bridge.vars_reif_precv_bin..., bridge.vars_reif_value_bin...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}}())) == Set([bridge.cons_reif_value..., bridge.cons_reif_precv...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}())) == Set(bridge.cons_implication)
    end

    @testset "Set of variables" begin
        @test length(bridge.vars_reif_precv) == dim - 1
        @test length(bridge.vars_reif_value) == dim - 1
        @test length(bridge.vars_reif_precv_bin) == dim - 1
        @test length(bridge.vars_reif_value_bin) == dim - 1
        
        for i in 1:(dim - 1)
            @test MOI.is_valid(model, bridge.vars_reif_precv[i])
            @test MOI.is_valid(model, bridge.vars_reif_value[i])
            @test MOI.is_valid(model, bridge.vars_reif_precv_bin[i])
            @test MOI.is_valid(model, bridge.vars_reif_value_bin[i])

            @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_reif_precv_bin[i]) == MOI.ZeroOne()
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_reif_precv_bin[i]) == bridge.vars_reif_precv[i]

            @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_reif_value_bin[i]) == MOI.ZeroOne()
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_reif_value_bin[i]) == bridge.vars_reif_value[i]
        end
    end

    @testset "Reify equality to value" begin
        @test length(bridge.cons_reif_value) == dim - 1

        for i in 1:(dim - 1)
            @test MOI.is_valid(model, bridge.cons_reif_value[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_reif_value[i]) == CP.Reification(MOI.EqualTo(zero(T)))
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_reif_value[i])

            @test length(f.terms) == 2
            @test f.constants == [zero(T), -T(4)]

            t1 = f.terms[1]
            @test t1.output_index == 1
            @test t1.scalar_term.coefficient === one(T)
            @test t1.scalar_term.variable == bridge.vars_reif_value[i]

            t2 = f.terms[2]
            @test t2.output_index == 2
            @test t2.scalar_term.coefficient === one(T)
            @test t2.scalar_term.variable == x[i + 1]
        end
    end

    @testset "Reify equality to before" begin
        @test length(bridge.cons_reif_precv) == dim - 1

        for i in 1:(dim - 1)
            @test MOI.is_valid(model, bridge.cons_reif_precv[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_reif_precv[i]) == CP.Reification(MOI.EqualTo(zero(T)))
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_reif_precv[i])

            @test length(f.terms) == 2
            @test f.constants == [zero(T), -T(2)]

            t1 = f.terms[1]
            @test t1.output_index == 1
            @test t1.scalar_term.coefficient === one(T)
            @test t1.scalar_term.variable == bridge.vars_reif_precv[i]

            t2 = f.terms[2]
            @test t2.output_index == 2
            @test t2.scalar_term.coefficient === one(T)
            @test t2.scalar_term.variable == x[i]
        end
    end

    @testset "Implications" begin
        @test length(bridge.cons_implication) == dim - 1

        for i in 2:dim
            @test MOI.is_valid(model, bridge.cons_implication[i - 1])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_implication[i - 1]) == MOI.LessThan(zero(T))
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_implication[i - 1])
            @test length(f.terms) == i
            @test abs(f.constant) === zero(T)

            t1 = f.terms[1]
            t1.coefficient === one(T)
            t1.variable == bridge.vars_reif_value[i - 1]

            for j in 2:i
                t = f.terms[j]
                @test t.coefficient === -one(T)
                @test t.variable == bridge.vars_reif_precv[j - 1]
            end
        end
    end
end
