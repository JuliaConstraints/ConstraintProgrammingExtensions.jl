@testset "AllDifferentExceptConstants2Reification: $(fct_type), dimension $(dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], T in [Int, Float64]
    base_model = if T == Int
        IntReificationEqualToModel{T}()
    elseif T == Float64
        FloatReificationEqualToModel{T}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.AllDifferentExceptConstants2Reification{T}(mock)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Reification{MOI.EqualTo{T}},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.AllDifferentExceptConstants{T},
    )

    if T == Int
        x, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:dim])
    elseif T == Float64
        x = MOI.add_variables(model, dim)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables(x)
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.VariableIndex.(x))
    else
        @assert false
    end
    values_set = Set([zero(T), one(T)])
    c = MOI.add_constraint(model, fct, CP.AllDifferentExceptConstants(dim, values_set))

    for i in 1:dim
        @test MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.AllDifferentExceptConstants}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.AllDifferentExceptConstants) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}),
            (MOI.ScalarAffineFunction{T}, CP.Reification{CP.DifferentFrom{T}}),
            (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == dim * length(values_set) + dim * (dim - 1) / 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VariableIndex, MOI.ZeroOne}()) == dim * length(values_set) + dim * (dim - 1) / 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}}()) == dim * length(values_set)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, CP.Reification{CP.DifferentFrom{T}}}()) == dim * (dim - 1) / 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == dim * (dim - 1) / 2

        @test Set(MOI.get(bridge, MOI.ListOfVariableIndices())) == Set([vec(collect(values(bridge.vars_compare)))..., vec(collect(values(bridge.vars_different)))...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.ZeroOne}())) == Set([vec(collect(values(bridge.vars_compare_bin)))..., vec(collect(values(bridge.vars_different_bin)))...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}}())) == Set(vec(bridge.cons_compare_reif))
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, CP.Reification{CP.DifferentFrom{T}}}())) == Set(collect(values(bridge.cons_different_reif)))
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}())) == Set(collect(values(bridge.cons)))
    end

    @testset "Set of variables" begin
        @test length(bridge.vars_compare) == dim * length(values_set)
        @test length(bridge.vars_compare_bin) == dim * length(values_set)

        for i in 1:dim
            for j in 1:2
                @test MOI.is_valid(model, bridge.vars_compare[i, j])
                @test MOI.is_valid(model, bridge.vars_compare_bin[i, j])
            end
            for j in 3:dim
                @test (i, j) ∉ keys(bridge.vars_compare)
                @test (i, j) ∉ keys(bridge.vars_compare_bin)
            end
        end

        @test length(bridge.vars_different) == dim * (dim - 1) / 2
        @test length(bridge.vars_different_bin) == dim * (dim - 1) / 2

        for i in 1:dim
            for j in 1:i
                @test (i, j) ∉ keys(bridge.vars_different)
                @test (i, j) ∉ keys(bridge.vars_different_bin)
            end
            for j in (i + 1):dim
                @test MOI.is_valid(model, bridge.vars_different[i, j])
                @test MOI.is_valid(model, bridge.vars_different_bin[i, j])
            end
        end
    end

    @testset "Compare array values to excluded values" begin
        @test length(bridge.cons_compare_reif) == dim * length(values_set)

        for i in 1:dim
            for j in 1:length(values_set)
                @test MOI.is_valid(model, bridge.cons_compare_reif[i, j])
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_compare_reif[i, j]) == CP.Reification(MOI.EqualTo(zero(T)))
                f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_compare_reif[i, j])
                @test length(f.terms) == 2
                @test f.constants == [zero(T), -T(j - 1)]
                
                t1 = f.terms[1]
                @test t1.output_index == 1
                @test t1.scalar_term.coefficient === one(T)
                @test t1.scalar_term.variable == bridge.vars_compare[i, j]

                t2 = f.terms[2]
                @test t2.output_index == 2
                @test t2.scalar_term.coefficient === one(T)
                @test t2.scalar_term.variable == x[i]
            end
        end
    end

    @testset "Compare array variables" begin
        @test length(bridge.cons_different_reif) == dim * (dim - 1) / 2

        for i in 1:dim
            for j in (i+1):dim
                @test MOI.is_valid(model, bridge.cons_different_reif[i, j])
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_different_reif[i, j]) == CP.Reification(CP.DifferentFrom(zero(T)))
                f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_different_reif[i, j])
                @test length(f.terms) == 3

                t1 = f.terms[1]
                @test t1.output_index == 1
                @test t1.scalar_term.coefficient === one(T)
                @test t1.scalar_term.variable == bridge.vars_different[i, j]

                t2 = f.terms[2]
                @test t2.output_index == 2
                @test t2.scalar_term.coefficient === one(T)
                @test t2.scalar_term.variable == x[i]

                t3 = f.terms[3]
                @test t3.output_index == 2
                @test t3.scalar_term.coefficient === -one(T)
                @test t3.scalar_term.variable == x[j]
            end
        end
    end

    @testset "Disjunction" begin
        @test length(bridge.cons) == dim * (dim - 1) / 2

        for i in 1:dim
            for j in (i+1):dim
                @test MOI.is_valid(model, bridge.cons[i, j])
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons[i, j]) == MOI.GreaterThan(one(T))
                f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons[i, j])
                @test length(f.terms) == 1 + 2 * length(values_set)

                for k in 1:length(values_set)
                    t1 = f.terms[k]
                    @test t1.coefficient === one(T)
                    @test t1.variable == bridge.vars_compare[i, k]

                    t2 = f.terms[length(values_set) + k]
                    @test t2.coefficient === one(T)
                    @test t2.variable == bridge.vars_compare[j, k]
                end

                t = f.terms[2 * length(values_set) + 1]
                @test t.coefficient === one(T)
                @test t.variable == bridge.vars_different[i, j]
            end
        end
    end
end
