@testset "VectorDomain2MILP: $(fct_type), dimension $(dim), $(n_values) values, $(T)" for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], n_values in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.VectorDomain2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    end
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.VectorDomain{T},
    )

    if T == Int
        x, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:dim])
    elseif T == Float64
        x = MOI.add_variables(model, dim)
    end
    x_values = Set([
        collect((one(T) + T(i)):(T(dim) + T(i)))
        for i in 1:n_values
    ])
    x_vector = collect(x_values) # Use collect() to get the same order as in the bridge.

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables(x)
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.(x))
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.VectorDomain(dim, x_values))

    for i in 1:dim
        MOI.is_valid(model, x[i])
    end
    @test MOI.is_valid(model, c)

    bridge = first(MOIBC.bridges(model))[2]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.SingleVariable, CP.VectorDomain{T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.SingleVariable, MOI.ZeroOne),
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == n_values
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == n_values
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 1 + dim

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}()) == bridge.vars_bin
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.con_choose_one, bridge.cons_values...]
    end

    @testset "New variables" begin
        @test length(bridge.vars) == n_values
        @test length(bridge.vars_bin) == n_values

        for i in 1:n_values
            @test MOI.is_valid(model, bridge.vars[i])
            @test MOI.is_valid(model, bridge.vars_bin[i])
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_bin[i]) == MOI.SingleVariable(bridge.vars[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_bin[i]) == MOI.ZeroOne()
        end
    end

    @testset "Choose one" begin
        @test MOI.is_valid(model, bridge.con_choose_one)
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_choose_one) == MOI.EqualTo(one(T))

        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_choose_one)
        @test length(f.terms) == n_values
        @test f.constant === zero(T)

        for i in 1:n_values
            t = f.terms[i]
            @test t.coefficient === one(T)
            @test t.variable_index == bridge.vars[i]
        end
    end

    @testset "Values" begin
        @test length(bridge.cons_values) == dim

        for i in 1:dim
            @test MOI.is_valid(model, bridge.cons_values[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons_values[i]) == MOI.EqualTo(zero(T))

            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons_values[i])
            @test length(f.terms) == 1 + n_values
            @test f.constant === zero(T)

            t1 = f.terms[1]
            @test t1.coefficient === one(T)
            @test t1.variable_index == x[i]

            for j in 1:n_values
                t = f.terms[1 + j]
                @test t.coefficient === -x_vector[j][i]
                @test t.variable_index == bridge.vars[j]
            end
        end
    end
end
