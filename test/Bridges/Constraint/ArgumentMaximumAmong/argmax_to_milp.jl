@testset "ArgumentMaximumAmong2MILP: $(fct_type), dimension $(array_dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], array_dim in [2, 3], T in [Int, Float64]
    dim = 1 + array_dim
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.ArgumentMaximumAmong2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.ArgumentMaximumAmong,
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

    @test_throws AssertionError MOI.add_constraint(model, fct, CP.ArgumentMaximumAmong(array_dim))

    for i in 1:array_dim
        MOI.add_constraint(model, x[1 + i], MOI.GreaterThan(zero(T)))
        MOI.add_constraint(model, x[1 + i], MOI.LessThan(one(T)))
    end
    c = MOI.add_constraint(model, fct, CP.ArgumentMaximumAmong(array_dim))

    for i in 1:dim
        @test MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.ArgumentMaximumAmong}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.ArgumentMaximumAmong) == typeof(bridge)
        if T == Int
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,), (MOI.Integer,)]
        elseif T == Float64
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        else
            @assert false
        end
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
            (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == array_dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == array_dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == array_dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == array_dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 1

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == bridge.vars
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}())) == Set(bridge.vars_bin)
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}())) == Set(bridge.cons_gt)
        @test Set(MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}())) == Set(bridge.cons_lt)
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.con_choose_one]
    end

    @testset "Binary variables" begin
        @test length(bridge.vars) == array_dim
        for i in 1:array_dim
            @test MOI.is_valid(model, bridge.vars[i])
        end

        @test MOI.is_valid(model, bridge.con_choose_one)
        s = MOI.get(model, MOI.ConstraintSet(), bridge.con_choose_one)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_choose_one)

        @test typeof(s) == MOI.EqualTo{T}
        @test s.value == one(T)
        @test length(f.terms) == array_dim
        @test f.constant == zero(T)

        for i in 1:array_dim
            t = f.terms[i]
            @test t.coefficient === one(T)
            @test t.variabl == bridge.vars[i]
        end
    end

    @testset "Constraints: greater than" begin
        @test length(bridge.cons_gt) == array_dim
        for i in 1:array_dim
            @test MOI.is_valid(model, bridge.cons_gt[i])
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_gt[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_gt[i])

            @test typeof(s) == MOI.GreaterThan{T}
            @test s.lower == zero(T)
            @test length(f.terms) == 2
            @test f.constant == zero(T)
            
            t1 = f.terms[1]
            @test t1.coefficient === -one(T)
            @test t1.variabl == x[i + 1]
            
            t2 = f.terms[2]
            @test t2.coefficient === one(T)
            @test t2.variabl == bridge.var_max
        end
    end

    @testset "Constraints: less than" begin
        @test length(bridge.cons_lt) == array_dim
        for i in 1:array_dim
            @test MOI.is_valid(model, bridge.cons_lt[i])
            s = MOI.get(model, MOI.ConstraintSet(), bridge.cons_lt[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_lt[i])

            @test typeof(s) == MOI.LessThan{T}
            @test s.upper == zero(T)
            @test length(f.terms) == 3
            @test f.constant == -one(T)
            
            t1 = f.terms[1]
            @test t1.coefficient === -one(T)
            @test t1.variabl == x[i + 1]
            
            t2 = f.terms[2]
            @test t2.coefficient === one(T)
            @test t2.variabl == bridge.vars[i]
            
            t3 = f.terms[3]
            @test t3.coefficient === one(T)
            @test t3.variabl == bridge.var_max
        end
    end

    @testset "Constraints: index" begin
        @test MOI.is_valid(model, bridge.con_index)
        s = MOI.get(model, MOI.ConstraintSet(), bridge.con_index)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_index)

        @test typeof(s) == MOI.EqualTo{T}
        @test s.value == zero(T)
        @test length(f.terms) == 1 + array_dim
        @test f.constant == zero(T)
        
        t1 = f.terms[1]
        @test t1.coefficient === one(T)
        @test t1.variabl == x[1]

        for i in 1:array_dim
            t = f.terms[1 + i]
            @test t.coefficient === -T(i)
            @test t.variabl == bridge.vars[i]
        end
    end
end
