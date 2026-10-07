@testset "SortPermutation2MILP: $(fct_type), dimension $(array_dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], array_dim in [2, 3], T in [Int, Float64]
    dim = 3 * array_dim
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.SortPermutation2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    end
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.ZeroOne)
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
        MOIU.vectorize(x)
    else
        @assert false
    end

    @test_throws AssertionError MOI.add_constraint(model, fct, CP.SortPermutation(array_dim))

    for i in 1:array_dim
        MOI.add_constraint(model, x[array_dim + i], MOI.LessThan(T(4)))
        MOI.add_constraint(model, x[array_dim + i], MOI.GreaterThan(-T(4)))
    end

    c = MOI.add_constraint(model, fct, CP.SortPermutation(array_dim))

    for i in 1:dim
        @test MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.SortPermutation}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.SortPermutation) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 2 * array_dim ^ 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VariableIndex, MOI.ZeroOne}()) == array_dim ^ 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 4 * array_dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == array_dim ^ 2
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == array_dim ^ 2 + array_dim - 1

        @test Set(MOI.get(bridge, MOI.ListOfVariableIndices())) == Set(vcat(bridge.vars_flow, bridge.vars_unicity))
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.ZeroOne}()) == bridge.vars_unicity_bin
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == vcat(bridge.cons_transportation_x, bridge.cons_transportation_y, bridge.cons_unicity_x, bridge.cons_unicity_y)
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == vec(bridge.cons_flow_lt)
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == vcat(vec(bridge.cons_flow_gt), bridge.cons_sort)
    end

    @testset "Variables" begin
        @test length(bridge.vars_flow) == array_dim ^ 2
        @test length(bridge.vars_unicity) == array_dim ^ 2
        @test length(bridge.vars_unicity_bin) == array_dim ^ 2

        for i in 1:array_dim
            for j in 1:array_dim
                @test MOI.is_valid(model, bridge.vars_flow[i, j])
                @test MOI.is_valid(model, bridge.vars_unicity[i, j])
                @test MOI.is_valid(model, bridge.vars_unicity_bin[i, j])
            end
        end
    end

    @testset "Constraints: transportation" begin
        @test length(bridge.cons_transportation_x) == array_dim
        @test length(bridge.cons_transportation_y) == array_dim
        
        for i in 1:array_dim
            @test MOI.is_valid(model, bridge.cons_transportation_x[i])
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_transportation_x[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_transportation_x[i])

            @test s == MOI.EqualTo(zero(T))
            @test length(f.terms) == 1 + array_dim
            @test f.constant == zero(T)

            t1 = f.terms[1]
            @test t1.coefficient === one(T)
            @test t1.variable == x[i]

            for j in 1:array_dim
                t = f.terms[1 + j]
                @test t.coefficient === -one(T)
                @test t.variable == bridge.vars_flow[i, j]
            end
        end
        
        for j in 1:array_dim
            @test MOI.is_valid(model, bridge.cons_transportation_y[j])
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_transportation_y[j])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_transportation_y[j])

            @test s == MOI.EqualTo(zero(T))
            @test length(f.terms) == 1 + array_dim
            @test f.constant == zero(T)

            t1 = f.terms[1]
            @test t1.coefficient === one(T)
            @test t1.variable == x[array_dim + j]

            for i in 1:array_dim
                t = f.terms[1 + i]
                @test t.coefficient === -one(T)
                @test t.variable == bridge.vars_flow[i, j]
            end
        end
    end

    @testset "Constraints: unicity" begin
        @test length(bridge.cons_unicity_x) == array_dim
        @test length(bridge.cons_unicity_y) == array_dim
        
        for i in 1:array_dim
            @test MOI.is_valid(model, bridge.cons_unicity_x[i])
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_unicity_x[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_unicity_x[i])

            @test s == MOI.EqualTo(one(T))
            @test length(f.terms) == array_dim
            @test f.constant == zero(T)

            for j in 1:array_dim
                t = f.terms[j]
                @test t.coefficient === one(T)
                @test t.variable == bridge.vars_unicity[i, j]
            end
        end
        
        for j in 1:array_dim
            @test MOI.is_valid(model, bridge.cons_unicity_y[j])
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_unicity_y[j])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_unicity_y[j])

            @test s == MOI.EqualTo(one(T))
            @test length(f.terms) == array_dim
            @test f.constant == zero(T)

            for i in 1:array_dim
                t = f.terms[i]
                @test t.coefficient === one(T)
                @test t.variable == bridge.vars_unicity[i, j]
            end
        end
    end

    @testset "Constraints: unicity of flows" begin
        @test length(bridge.cons_flow_gt) == array_dim ^ 2
        @test length(bridge.cons_flow_lt) == array_dim ^ 2
        
        for i in 1:array_dim
            for j in 1:array_dim
                @test MOI.is_valid(model, bridge.cons_flow_gt[i, j])
                @test MOI.is_valid(model, bridge.cons_flow_lt[i, j])
                
                sgt = MOI.get(model, MOI.ConstraintSet(), bridge.cons_flow_gt[i, j])
                fgt = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_flow_gt[i, j])
                
                slt = MOI.get(model, MOI.ConstraintSet(), bridge.cons_flow_lt[i, j])
                flt = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_flow_lt[i, j])

                @test sgt == MOI.GreaterThan(zero(T))
                @test slt == MOI.LessThan(zero(T))

                @test length(flt.terms) == 2
                @test flt.constant == zero(T)
                @test length(fgt.terms) == 2
                @test fgt.constant == zero(T)
                
                t1lt = flt.terms[1]
                @test t1lt.coefficient === one(T)
                @test t1lt.variable == bridge.vars_flow[i, j]
                
                t1gt = fgt.terms[1]
                @test t1gt.coefficient === one(T)
                @test t1gt.variable == bridge.vars_flow[i, j]
                
                t2lt = flt.terms[2]
                @test t2lt.coefficient === one(T) * 4
                @test t2lt.variable == bridge.vars_unicity[i, j]
                
                t2gt = fgt.terms[2]
                @test t2gt.coefficient === one(T) * -4
                @test t2gt.variable == bridge.vars_unicity[i, j]
            end
        end
    end

    @testset "Constraint: sorted array" begin
        @test length(bridge.cons_sort) == array_dim - 1
        
        for i in 1:(array_dim - 1)
            @test MOI.is_valid(model, bridge.cons_sort[i])
                
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_sort[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_sort[i])

            @test s == MOI.GreaterThan(zero(T))
            @test length(f.terms) == 2
                
            t1 = f.terms[1]
            @test t1.coefficient === one(T)
            @test t1.variable == x[i]
            
            t2 = f.terms[2]
            @test t2.coefficient === -one(T)
            @test t2.variable == x[i + 1]
        end
    end

    @testset "Constraint: permutation array" begin
        @test length(bridge.cons_perm) == array_dim
        
        for i in 1:array_dim
            @test MOI.is_valid(model, bridge.cons_perm[i])
                
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_perm[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_perm[i])

            @test s == MOI.EqualTo(zero(T))
            @test length(f.terms) == array_dim + 1
                
            t1 = f.terms[1]
            @test t1.coefficient === one(T)
            @test t1.variable == x[2 * array_dim + i]
            
            for j in 1:array_dim
                t = f.terms[1 + j]
                @test t.coefficient === -T(j)
                @test t.variable == bridge.vars_unicity[i, j]
            end
        end
    end
end
