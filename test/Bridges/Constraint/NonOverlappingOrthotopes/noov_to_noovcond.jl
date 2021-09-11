@testset "NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopes: $(fct_type), orthotopes $(n_ortho), dimension $(dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], n_ortho in [2, 3], dim in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(ConditionallyNonOverlappingOrthotopesModel{T}())
    model = COIB.NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopes{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.NonOverlappingOrthotopes{CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES},
    )

    n_vars_position = n_ortho * dim
    n_vars_size = n_ortho * dim
    if T == Int
        x_pos, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:n_vars_position])
        x_sze, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:n_vars_size])
        x_end, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:n_vars_position])
    elseif T == Float64
        x_pos = MOI.add_variables(model, n_vars_position)
        x_sze = MOI.add_variables(model, n_vars_size)
        x_end = MOI.add_variables(model, n_vars_position)
    end
    x_ortho = [
        [
            x_pos[(1 + (i - 1) * dim) : (i * dim)], 
            x_sze[(1 + (i - 1) * dim) : (i * dim)], 
            x_end[(1 + (i - 1) * dim) : (i * dim)],
        ]
        for i in 1:n_ortho
    ]
    x = vcat([vcat(x_ortho[i]...) for i in 1:n_ortho]...)

    # Test the construction of x before going on (no loops to ease checking 
    # for correctness). 
    @test length(x_pos) == dim * n_ortho
    @test length(x_sze) == dim * n_ortho
    @test length(x_end) == dim * n_ortho
    @test length(x) == 3 * dim * n_ortho
    if n_ortho >= 1
        @test x[(0 * dim + 1):(1 * dim)] == x_pos[(0 * dim + 1):(1 * dim)]
        @test x[(1 * dim + 1):(2 * dim)] == x_sze[(0 * dim + 1):(1 * dim)]
        @test x[(2 * dim + 1):(3 * dim)] == x_end[(0 * dim + 1):(1 * dim)]
    end
    if n_ortho >= 2
        @test x[(3 * dim + 1):(4 * dim)] == x_pos[(1 * dim + 1):(2 * dim)]
        @test x[(4 * dim + 1):(5 * dim)] == x_sze[(1 * dim + 1):(2 * dim)]
        @test x[(5 * dim + 1):(6 * dim)] == x_end[(1 * dim + 1):(2 * dim)]
    end
    if n_ortho >= 3
        @test x[(6 * dim + 1):(7 * dim)] == x_pos[(2 * dim + 1):(3 * dim)]
        @test x[(7 * dim + 1):(8 * dim)] == x_sze[(2 * dim + 1):(3 * dim)]
        @test x[(8 * dim + 1):(9 * dim)] == x_end[(2 * dim + 1):(3 * dim)]
    end
    if n_ortho >= 4
        @assert false
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables(x)
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.(x))
    else
        @assert false
    end

    c = MOI.add_constraint(model, fct, CP.NonOverlappingOrthotopes(n_ortho, dim))

    for i in 1:(3 * dim *  n_ortho)
        @test MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.NonOverlappingOrthotopes}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.NonOverlappingOrthotopes{CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.EqualTo{T},)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.EqualTo{T}}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES}}()) == 1

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == [bridge.var]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.EqualTo{T}}()) == [bridge.var_con]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES}}()) == [bridge.con]
    end

    @testset "New variable" begin
        @test MOI.is_valid(model, bridge.var)
        @test MOI.is_valid(model, bridge.var_con)
        @test MOI.get(model, MOI.ConstraintSet(), bridge.var_con) == MOI.EqualTo(one(T))
        @test MOI.get(model, MOI.ConstraintFunction(), bridge.var_con) == MOI.SingleVariable(bridge.var)
    end

    @testset "New constraint" begin
        @test MOI.is_valid(model, bridge.con)
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con) == CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES}(n_ortho, dim)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con)

        for i in 1:length(f.terms)
            t = f.terms[i]
            @test t.output_index === i
            @test t.scalar_term.coefficient === one(T)
        end

        f_vars = [t.scalar_term.variabl for t in f.terms]
        @test length(f_vars) == 3 * dim * n_ortho + n_ortho

        if n_ortho >= 1
            @test f_vars[(0 * dim + 1):(1 * dim)] == x_pos[(0 * dim + 1):(1 * dim)]
            @test f_vars[(1 * dim + 1):(2 * dim)] == x_sze[(0 * dim + 1):(1 * dim)]
            @test f_vars[(2 * dim + 1):(3 * dim)] == x_end[(0 * dim + 1):(1 * dim)]
            @test f_vars[3 * dim + 1] == bridge.var
        end
        if n_ortho >= 2
            @test f_vars[(3 * dim + 2):(4 * dim + 1)] == x_pos[(1 * dim + 1):(2 * dim)]
            @test f_vars[(4 * dim + 2):(5 * dim + 1)] == x_sze[(1 * dim + 1):(2 * dim)]
            @test f_vars[(5 * dim + 2):(6 * dim + 1)] == x_end[(1 * dim + 1):(2 * dim)]
            @test f_vars[6 * dim + 2] == bridge.var
        end
        if n_ortho >= 3
            @test f_vars[(6 * dim + 3):(7 * dim + 2)] == x_pos[(2 * dim + 1):(3 * dim)]
            @test f_vars[(7 * dim + 3):(8 * dim + 2)] == x_sze[(2 * dim + 1):(3 * dim)]
            @test f_vars[(8 * dim + 3):(9 * dim + 2)] == x_end[(2 * dim + 1):(3 * dim)]
            @test f_vars[9 * dim + 3] == bridge.var
        end
        if n_ortho >= 4
            @assert false
        end
    end
end
