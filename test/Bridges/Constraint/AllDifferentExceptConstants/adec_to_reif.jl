@testset "AllDifferentExceptConstants2Reification: $(fct_type), dimension $(dim), $(T)" for fct_type in ["vector of variables"], dim in [2], T in [Int]
    # for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], T in [Int, Float64]
    base_model = if T == Int
        IntReificationEqualToModel{T}()
    elseif T == Float64
        FloatReificationEqualToModel{T}()
    else
        @assert false
    end
    mock = MOIU.MockOptimizer(base_model)
    model = COIB.AllDifferentExceptConstants2Reification{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
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
        MOIU.vectorize(MOI.SingleVariable.(x))
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
            (MOI.SingleVariable, MOI.ZeroOne),
            (MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}),
            (MOI.ScalarAffineFunction{T}, CP.Reification{CP.DifferentFrom{T}}),
            (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == dim * length(values_set) + dim * (dim - 1) / 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == dim * length(values_set) + dim * (dim - 1) / 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}}()) == dim * length(values_set)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, CP.Reification{CP.DifferentFrom{T}}}()) == dim * (dim - 1) / 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == dim * (dim - 1) / 2

        @test Set(MOI.get(bridge, MOI.ListOfVariableIndices())) == Set([vec(collect(values(bridge.vars_compare)))..., vec(collect(values(bridge.vars_different)))...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}())) == Set([vec(collect(values(bridge.vars_compare_bin)))..., vec(collect(values(bridge.vars_different_bin)))...])
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}}())) == Set(vec(bridge.cons_compare_reif))
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, CP.Reification{CP.DifferentFrom{T}}}())) == Set(collect(values(bridge.cons_different_reif)))
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}())) == Set(collect(values(bridge.cons)))
    end

    # @testset "Set of constraints" begin
    #     @test length(bridge.cons) == dim * (dim - 1) / 2
    #     for i in 1:dim
    #         for j in (i+1):dim
    #             @test MOI.is_valid(model, bridge.cons[i, j])
    #             @test MOI.get(model, MOI.ConstraintSet(), bridge.cons[i, j]) == CP.Disjunction((CP.Domain(Set([zero(T), one(T)])), CP.Domain(Set([zero(T), one(T)])), CP.DifferentFrom(zero(T))))
    #             f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons[i, j])
    #             @test length(f.terms) == 4

    #             t1 = f.terms[1]
    #             @test t1.output_index == 1
    #             @test t1.scalar_term.coefficient === one(T)
    #             @test t1.scalar_term.variable_index == x[i]

    #             t2 = f.terms[2]
    #             @test t2.output_index == 2
    #             @test t2.scalar_term.coefficient === one(T)
    #             @test t2.scalar_term.variable_index == x[j]

    #             t3 = f.terms[3]
    #             @test t3.output_index == 3
    #             @test t3.scalar_term.coefficient === one(T)
    #             @test t3.scalar_term.variable_index == x[i]

    #             t4 = f.terms[4]
    #             @test t4.output_index == 3
    #             @test t4.scalar_term.coefficient === -one(T)
    #             @test t4.scalar_term.variable_index == x[j]
    #         end
    #     end
    # end
end
