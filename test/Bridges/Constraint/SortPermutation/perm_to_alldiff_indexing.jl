@testset "SortPermutation2AllDifferent: $(fct_type), dimension $(array_dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], array_dim in [2, 3], T in [Int, Float64]
    dim = 3 * array_dim
    mock = MOIU.MockOptimizer(AllDifferentIndexingModel{T}())
    model = COIB.SortPermutation2AllDifferent{T}(mock)

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
        CP.ElementVariableArray,
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.SortPermutation,
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

    c = MOI.add_constraint(model, fct, CP.SortPermutation(array_dim))

    for i in 1:dim
        @test MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.SortPermutation}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.MinimumAmong) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.AllDifferent),
            (MOI.ScalarAffineFunction{T}, CP.ElementVariableArray),
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.AllDifferent}()) == 1
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, CP.ElementVariableArray}()) == array_dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == array_dim - 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.AllDifferent}()) == [bridge.con_alldiff]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, CP.ElementVariableArray}()) == bridge.cons_value
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == bridge.cons_sort
    end

    @testset "Constraint: all difference" begin
        @test MOI.is_valid(model, bridge.con_alldiff)
        s = MOI.get(model, MOI.ConstraintSet(), bridge.con_alldiff)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_alldiff)

        @test typeof(s) == CP.AllDifferent
        @test length(f.terms) == array_dim
        @test f.constants == zeros(T, array_dim)
        
        for i in 1:array_dim
            t = f.terms[i]
            @test t.output_index === i
            @test t.scalar_term.coefficient === one(T)
            @test t.scalar_term.variabl == x[2 * array_dim + i]
        end
    end

    @testset "Constraints: greater than" begin
        @test length(bridge.cons_sort) == array_dim - 1
        for i in 1:(array_dim - 1)
            @test MOI.is_valid(model, bridge.cons_sort[i])
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_sort[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_sort[i])

            @test typeof(s) == MOI.GreaterThan{T}
            @test s.lower == zero(T)
            @test length(f.terms) == 2
            @test f.constant == zero(T)
            
            t1 = f.terms[1]
            @test t1.coefficient === one(T)
            @test t1.variabl == x[i]
            
            t2 = f.terms[2]
            @test t2.coefficient === -one(T)
            @test t2.variabl == x[i + 1]
        end
    end

    @testset "Constraints: array index" begin
        @test length(bridge.cons_value) == array_dim
        for i in 1:array_dim
            @test MOI.is_valid(model, bridge.cons_value[i])
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_value[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_value[i])

            @test typeof(s) == CP.ElementVariableArray
            @test length(f.terms) == 2 + array_dim
            @test f.constants == zeros(T, 2 + array_dim)
            
            t1 = f.terms[1]
            @test t1.output_index === 1
            @test t1.scalar_term.coefficient === one(T)
            @test t1.scalar_term.variabl == x[i]
            
            t2 = f.terms[2]
            @test t2.output_index === 2
            @test t2.scalar_term.coefficient === one(T)
            @test t2.scalar_term.variabl == x[2 * array_dim + i]
            
            t3 = f.terms[3]
            @test t3.output_index === 3
            @test t3.scalar_term.coefficient === one(T)
            @test t3.scalar_term.variabl == x[array_dim + 1]
            
            t4 = f.terms[4]
            @test t4.output_index === 4
            @test t4.scalar_term.coefficient === one(T)
            @test t4.scalar_term.variabl == x[array_dim + 2]
        end
    end
end
