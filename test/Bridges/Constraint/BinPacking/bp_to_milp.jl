@testset "BinPacking2MILP: $(fct_type), $(n_bins) bin, 2 items, $(T)" for fct_type in ["vector of variables", "vector affine function"], n_bins in [1, 2], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.BinPacking2MILP{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T},
    )

    n_items = 2
    weights = T[3, 2]

    if T == Int
        x_load_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
        if n_bins == 1
            x_load_2 = nothing
        elseif n_bins == 2
            x_load_2, _ = MOI.add_constrained_variable(model, MOI.Integer())
        else
            @assert false
        end
    elseif T == Float64
        x_load_1 = MOI.add_variable(model)
        if n_bins == 1
            x_load_2 = nothing
        elseif n_bins == 2
            x_load_2 = MOI.add_variable(model)
        else
            @assert false
        end
    end
    x_bin_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x_bin_2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    fct = if fct_type == "vector of variables"
        if n_bins == 1
            MOI.VectorOfVariables([x_load_1, x_bin_1, x_bin_2])
        elseif n_bins == 2
            MOI.VectorOfVariables([x_load_1, x_load_2, x_bin_1, x_bin_2])
        else
            @assert false
        end
    elseif fct_type == "vector affine function"
        if n_bins == 1
            MOIU.vectorize(MOI.VariableIndex.([x_load_1, x_bin_1, x_bin_2]))
        elseif n_bins == 2
            MOIU.vectorize(MOI.VariableIndex.([x_load_1, x_load_2, x_bin_1, x_bin_2]))
        else
            @assert false
        end
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(n_bins, n_items, weights))

    @test MOI.is_valid(model, x_load_1)
    if n_bins >= 2
        @test MOI.is_valid(model, x_load_2)
    end
    @test MOI.is_valid(model, x_bin_1)
    @test MOI.is_valid(model, x_bin_2)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [(MOI.ScalarAffineFunction{T}, MOI.EqualTo{T})]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == n_bins * n_items
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VariableIndex, MOI.ZeroOne}()) == n_bins * n_items
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == n_bins + 2 * n_items

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == vec(bridge.assign_var)
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.ZeroOne}()) == vec(bridge.assign_con)
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.assign_unique..., bridge.assign_number..., bridge.assign_load...]
    end

    @testset "Set of variables: one binary per item and per bin" begin
        @test length(bridge.assign_var) == n_items * n_bins
        for i in 1:(n_items * n_bins)
            @test MOI.is_valid(model, bridge.assign_var[i])
        end

        @test length(bridge.assign_con) == n_items * n_bins
        for i in 1:(n_items * n_bins)
            @test MOI.is_valid(model, bridge.assign_con[i])
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.assign_con[i]).variable == bridge.assign_var[i]
            @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_con[i]) == MOI.ZeroOne()
        end
    end

    @testset "One bin per item" begin
        @test length(bridge.assign_unique) == n_items
        for item in 1:n_items
            @test MOI.is_valid(model, bridge.assign_unique[item])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_unique[item])
            @test length(f.terms) == n_bins
            @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_unique[item]) == MOI.EqualTo(one(T))

            for bin in 1:n_bins
                t = f.terms[bin]
                @test t.coefficient === one(T)
                @test t.variable == bridge.assign_var[item, bin]
            end
        end
    end

    @testset "Relation between the integer and binary representation of bin assignment" begin
        @test length(bridge.assign_number) == n_items
        for item in 1:n_items
            @test MOI.is_valid(model, bridge.assign_number[item])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_number[item])
            @test length(f.terms) == n_bins + 1
            @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_number[item]) == MOI.EqualTo(zero(T))

            t = f.terms[1]
            @test t.coefficient === -one(T)
            @test t.variable == ((item == 1) ? x_bin_1 : x_bin_2)

            for bin in 1:n_bins
                t = f.terms[1 + bin]
                @test t.coefficient === T(bin)
                @test t.variable == bridge.assign_var[item, bin]
            end
        end
    end

    @testset "Load" begin
        @test length(bridge.assign_load) == n_bins
        for bin in 1:n_bins
            @test MOI.is_valid(model, bridge.assign_load[bin])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_load[bin])
            @test length(f.terms) == n_items + 1
            @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_load[bin]) == MOI.EqualTo(zero(T))

            t = f.terms[1]
            @test t.coefficient === -one(T)
            @test t.variable == ((bin == 1) ? x_load_1 : x_load_2)

            for item in 1:n_items
                t = f.terms[1 + item]
                @test t.coefficient === weights[item]
                @test t.variable == bridge.assign_var[item, bin]
            end
        end
    end
end
