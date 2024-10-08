@testset "AllDifferent2DifferentFrom: $(fct_type), dimension $(dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(DifferentFromModel{T}())
    model = COIB.AllDifferent2DifferentFrom{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        CP.DifferentFrom{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        MOI.AllDifferent,
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
    c = MOI.add_constraint(model, fct, MOI.AllDifferent(dim))

    for i in 1:dim
        @test MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, MOI.AllDifferent}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, MOI.AllDifferent) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [(MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T})]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T}}()) == div(dim * (dim - 1), 2)

        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T}}())) == Set(collect(values(bridge.cons)))
    end

    @testset "Set of constraints" begin
        @test length(bridge.cons) == div(dim * (dim - 1), 2)
        for i in 1:dim
            for j in (i+1):dim
                @test MOI.is_valid(model, bridge.cons[i, j])
                f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons[i, j])
                @test length(f.terms) == 2
                @test MOI.get(model, MOI.ConstraintSet(), bridge.cons[i, j]) == CP.DifferentFrom(zero(T))

                t1 = f.terms[1]
                @test t1.coefficient === one(T)
                @test t1.variable == x[i]

                t2 = f.terms[2]
                @test t2.coefficient === -one(T)
                @test t2.variable == x[j]
            end
        end
    end
end
