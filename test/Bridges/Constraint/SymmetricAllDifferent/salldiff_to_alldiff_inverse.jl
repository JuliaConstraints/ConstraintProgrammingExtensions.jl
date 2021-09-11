@testset "SymmetricAllDifferent2AllDifferentInverse: $(fct_type), dimension $(dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(AllDifferentInverseModel{T}())
    model = COIB.SymmetricAllDifferent2AllDifferentInverse{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.AllDifferent,
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Inverse,
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.SymmetricAllDifferent,
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
    c = MOI.add_constraint(model, fct, CP.SymmetricAllDifferent(dim))

    for i in 1:dim
        @test MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = first(MOIBC.bridges(model))[2]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VariableIndex, CP.SymmetricAllDifferent) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.AllDifferent),
            (MOI.VectorAffineFunction{T}, CP.Inverse),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.AllDifferent}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.Inverse}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.AllDifferent}()) == [bridge.con_all_diff]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.Inverse}()) == [bridge.con_inverse]
    end

    @testset "All different" begin
        @test MOI.is_valid(model, bridge.con_all_diff)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_all_diff)
        @test length(f.terms) == dim
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_all_diff) == CP.AllDifferent(dim)

        for i in 1:dim
            t = f.terms[i]
            @test t.output_index == i
            @test t.scalar_term.coefficient === one(T)
            @test t.scalar_term.variable == x[i]
        end
    end

    @testset "Inverse" begin
        @test MOI.is_valid(model, bridge.con_inverse)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_inverse)
        @test length(f.terms) == 2 * dim
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_inverse) == CP.Inverse(dim)

        for i in 1:dim
            t = f.terms[i]
            @test t.output_index == i
            @test t.scalar_term.coefficient === one(T)
            @test t.scalar_term.variable == x[i]

            t = f.terms[dim + i]
            @test t.output_index == dim + i
            @test t.scalar_term.coefficient === one(T)
            @test t.scalar_term.variable == x[i]
        end
    end
end
