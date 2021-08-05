@testset "Inverse2Reification: $(fct_type), dimension $(dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], T in [Int, Float64]
    base_model = if T == Int
        IntReificationEqualToModel{T}()
    elseif T == Float64
        FloatReificationEqualToModel{T}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.Inverse2Reification{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Reification{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Inverse,
    )
    
    if T == Int
        x, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:dim])
        y, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:dim])
    elseif T == Float64
        x = MOI.add_variables(model, dim)
        y = MOI.add_variables(model, dim)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x..., y...])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x..., y...]))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.Inverse(dim))

    for i in 1:dim
        @test MOI.is_valid(model, x[i])
        @test MOI.is_valid(model, y[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Inverse}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Inverse) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}),
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 2 * dim ^ 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == 2 * dim ^ 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}}()) == 2 * dim ^ 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == dim ^ 2

        @test Set(MOI.get(bridge, MOI.ListOfVariableIndices())) == Set([bridge.vars_first..., bridge.vars_second...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}())) == Set([bridge.vars_first_bin..., bridge.vars_second_bin...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}}())) == Set([bridge.cons_first_reif..., bridge.cons_second_reif...])
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == bridge.cons_equivalence
    end

    @testset "Set of variables" begin
        @test length(bridge.vars_first) == dim ^ 2
        @test length(bridge.vars_second) == dim ^ 2

        for i in 1:dim
            for j in 1:dim
                @test MOI.is_valid(model, bridge.vars_first[i, j])
                @test MOI.is_valid(model, bridge.vars_second[i, j])

                @test MOI.is_valid(model, bridge.vars_first_bin[i, j])
                @test MOI.is_valid(model, bridge.vars_second_bin[i, j])
                
                @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_first_bin[i, j]).variable == bridge.vars_first[i, j]
                @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_first_bin[i, j]) == MOI.ZeroOne()
                
                @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_second_bin[i, j]).variable == bridge.vars_second[i, j]
                @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_second_bin[i, j]) == MOI.ZeroOne()
            end
        end
    end

    @testset "Reification" begin
        @test length(bridge.cons_first_reif) == dim ^ 2
        @test length(bridge.cons_second_reif) == dim ^ 2

        for i in 1:dim
            for j in 1:dim
                @test MOI.is_valid(model, bridge.cons_first_reif[i, j])
                @test MOI.is_valid(model, bridge.cons_second_reif[i, j])
                
                f1 = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_first_reif[i, j])
                @test length(f1.terms) == 2
                @test f1.constants == T[zero(T), -T(j)]
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_first_reif[i, j]) == CP.Reification(MOI.EqualTo(zero(T)))

                t1 = f1.terms[1]
                @test t1.output_index == 1
                @test t1.scalar_term.coefficient === one(T)
                @test t1.scalar_term.variable_index == bridge.vars_first[i, j]

                t2 = f1.terms[2]
                @test t2.output_index == 2
                @test t2.scalar_term.coefficient === one(T)
                @test t2.scalar_term.variable_index == x[i]
                
                f2 = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_second_reif[i, j])
                @test length(f2.terms) == 2
                @test f2.constants == T[zero(T), -T(i)]
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_second_reif[i, j]) == CP.Reification(MOI.EqualTo(zero(T)))

                t1 = f2.terms[1]
                @test t1.output_index == 1
                @test t1.scalar_term.coefficient === one(T)
                @test t1.scalar_term.variable_index == bridge.vars_second[i, j]

                t2 = f2.terms[2]
                @test t2.output_index == 2
                @test t2.scalar_term.coefficient === one(T)
                @test t2.scalar_term.variable_index == y[j]
            end
        end
    end 

    @testset "Equivalence" begin
        @test length(bridge.cons_equivalence) == dim ^ 2

        for i in 1:dim
            for j in 1:dim
                @test MOI.is_valid(model, bridge.cons_equivalence[i, j])
                f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_equivalence[i, j])
                @test length(f.terms) == 2
                @test f.constant == zero(T)
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_equivalence[i, j]) == MOI.EqualTo(zero(T))
        
                t1 = f.terms[1]
                @test t1.coefficient === one(T)
                @test t1.variable_index == bridge.vars_first[i, j]
        
                t2 = f.terms[2]
                @test t2.coefficient === -one(T)
                @test t2.variable_index == bridge.vars_second[i, j]
            end
        end
    end
end
    