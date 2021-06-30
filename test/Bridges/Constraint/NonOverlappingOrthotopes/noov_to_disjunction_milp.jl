@testset "NonOverlappingOrthotopes2DisjunctionLinear: $(fct_type), orthotopes $(n_ortho), dimension $(dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], n_ortho in [2, 3], dim in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(DisjunctionModel{T}())
    model = COIB.NonOverlappingOrthotopes2DisjunctionLinear{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    if fct_type == "vector of variables"
        @test MOI.supports_constraint(
            model,
            MOI.VectorOfVariables,
            CP.Disjunction{NTuple{4, MOI.LessThan{T}}},
        )
        @test MOI.supports_constraint(
            model,
            MOI.VectorOfVariables,
            CP.Disjunction{NTuple{6, MOI.LessThan{T}}},
        )
        @test MOIB.supports_bridging_constraint(
            model,
            MOI.VectorOfVariables,
            CP.NonOverlappingOrthotopes,
        )
    elseif fct_type == "vector affine function"
        @test MOI.supports_constraint(
            model,
            MOI.VectorAffineFunction{T},
            CP.Disjunction{NTuple{4, MOI.LessThan{T}}},
        )
        @test MOI.supports_constraint(
            model,
            MOI.VectorAffineFunction{T},
            CP.Disjunction{NTuple{6, MOI.LessThan{T}}},
        )
        @test MOIB.supports_bridging_constraint(
            model,
            MOI.VectorAffineFunction{T},
            CP.NonOverlappingOrthotopes,
        )
    else
        @assert false
    end

    if T == Int
        x_pos, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:(dim * n_ortho)])
        x_sze, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:(dim * n_ortho)])
        x_end, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:(dim * n_ortho)])
    elseif T == Float64
        x_pos = MOI.add_variables(model, dim * n_ortho)
        x_sze = MOI.add_variables(model, dim * n_ortho)
        x_end = MOI.add_variables(model, dim * n_ortho)
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
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.NonOverlappingOrthotopes) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
            (MOI.VectorAffineFunction{T}, CP.Disjunction{NTuple{n, MOI.LessThan{T}} where n}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == n_ortho * dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Disjunction{NTuple{n, MOI.LessThan{T}} where n}}()) == Int(n_ortho * (n_ortho - 1) / 2)

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == collect(values(bridge.cons_ends))
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Disjunction{NTuple{n, MOI.LessThan{T}} where n}}()) == collect(values(bridge.cons_disjunction))
    end

    @testset "End-point constraints" begin
        @test length(bridge.cons_ends) == n_ortho * dim
        for i in 1:n_ortho
            for d in 1:dim
                @test MOI.is_valid(model, bridge.cons_ends[i, d])
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_ends[i, d]) == MOI.EqualTo(zero(T))
                f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_ends[i, d])

                @test length(f.terms) == 3

                t1 = f.terms[1]
                @test t1.coefficient === one(T)
                @test t1.variable_index === x_pos[(i - 1) * dim + d]

                t2 = f.terms[2]
                @test t2.coefficient === one(T)
                @test t2.variable_index === x_sze[(i - 1) * dim + d]

                t3 = f.terms[3]
                @test t3.coefficient === -one(T)
                @test t3.variable_index === x_end[(i - 1) * dim + d]
            end
        end
    end

    @testset "Disjunction constraints" begin
        @test length(bridge.cons_disjunction) == Int(n_ortho * (n_ortho - 1) / 2)
        for i in 1:n_ortho
            for j in 1:n_ortho
                if i < j
                    @test MOI.is_valid(model, bridge.cons_disjunction[i, j])
                    @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_disjunction[i, j]) isa CP.Disjunction

                    f_vector = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_disjunction[i, j])
                    @test length(f_vector.terms) == 3 * 2 * dim

                    f_scalars = MOIU.scalarize(f_vector)
                    @test length(f_scalars) == 2 * dim

                    for d in 1:dim
                        f1 = f_scalars[(d - 1) * 2 + 1]
                        f2 = f_scalars[(d - 1) * 2 + 2]

                        # Doesn't work, because == requires that the order 
                        # of the terms is the same.
                        # @test f1 == one(T) * MOI.SingleVariable(x_pos[(i - 1) * dim + d]) + one(T) * MOI.SingleVariable(x_sze[(i - 1) * dim + d]) - one(T) * MOI.SingleVariable(x_pos[(j - 1) * dim + d])

                        t = f1.terms[1]
                        @test t.coefficient === one(T)
                        @test t.variable_index === x_pos[(i - 1) * dim + d]

                        t = f1.terms[2]
                        @test t.coefficient === -one(T)
                        @test t.variable_index === x_pos[(j - 1) * dim + d]

                        t = f1.terms[3]
                        @test t.coefficient === one(T)
                        @test t.variable_index === x_sze[(i - 1) * dim + d]

                        t = f2.terms[1]
                        @test t.coefficient === -one(T)
                        @test t.variable_index === x_pos[(i - 1) * dim + d]

                        t = f2.terms[2]
                        @test t.coefficient === one(T)
                        @test t.variable_index === x_pos[(j - 1) * dim + d]

                        t = f2.terms[3]
                        @test t.coefficient === one(T)
                        @test t.variable_index === x_sze[(j - 1) * dim + d]
                    end
                end
            end
        end
    end
end
