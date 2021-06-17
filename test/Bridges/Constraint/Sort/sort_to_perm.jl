@testset "Sort2SortPermutation: $(fct_type), dimension $(array_dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], array_dim in [2, 3], T in [Int, Float64]
    dim = 2 * array_dim
    mock = MOIU.MockOptimizer(SortPermutationModel{T}())
    model = COIB.Sort2SortPermutation{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.SortPermutation,
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.Sort,
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

    c = MOI.add_constraint(model, fct, CP.Sort(array_dim))

    for i in 1:dim
        MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.Sort}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Sort) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.Integer,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.SingleVariable, MOI.Integer),
            (MOI.VectorAffineFunction{T}, CP.SortPermutation),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == array_dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}()) == array_dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.SortPermutation}()) == 1

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == bridge.vars
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.Integer}()) == bridge.vars_int
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.SortPermutation}()) == [bridge.con_perm]
    end

    @testset "Constraint: sort with permutation" begin
        @test MOI.is_valid(model, bridge.con_perm)
        s = MOI.get(model, MOI.ConstraintSet(), bridge.con_perm)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_perm)

        @test typeof(s) == CP.SortPermutation
        @test length(f.terms) == 3 * array_dim
        @test f.constants == zeros(T, 3 * array_dim)
        
        for i in 1:(2 * array_dim) # Sorted array and array to sort.
            t = f.terms[i]
            @test t.output_index === i
            @test t.scalar_term.coefficient === one(T)
            @test t.scalar_term.variable_index == x[i]
        end
        for i0 in 1:array_dim # Indices.
            i = 2 * array_dim + i0
            t = f.terms[i]
            @test t.output_index === i
            @test t.scalar_term.coefficient === one(T)
            @test t.scalar_term.variable_index == bridge.vars[i0]
        end
    end

    @testset "Constraints: integer" begin
        @test length(bridge.vars_int) == array_dim
        for i in 1:array_dim
            @test MOI.is_valid(model, bridge.vars[i])
            @test MOI.is_valid(model, bridge.vars_int[i])
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_int[i]) == MOI.SingleVariable(bridge.vars[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_int[i]) == MOI.Integer()
        end
    end
end
