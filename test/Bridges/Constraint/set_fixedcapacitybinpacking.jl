@testset "BinPacking2MILP: vector of variables, 1 bin, 2 items" begin
    mock = MOIU.MockOptimizer(MILPModel{Int}())
    model = COIB.BinPacking2MILP{Int}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.EqualTo{Int},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.BinPacking{Int},
    )

    n_items = 2
    n_bins = 1
    weights = [2, 2]
    
    x_load, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x_bin_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x_bin_2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c = MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x_load, x_bin_1, x_bin_2]),
        CP.BinPacking(n_bins, n_items, weights),
    )

    @test MOI.is_valid(model, x_load)
    @test MOI.is_valid(model, x_bin_1)
    @test MOI.is_valid(model, x_bin_2)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.BinPacking{Int}}(-1)]

    # Set of variables: one binary per item and per bin.
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

    # One bin per item.
    @test length(bridge.assign_unique) == n_items
    i = 1
    for item in 1:n_items
        @test MOI.is_valid(model, bridge.assign_unique[item])
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_unique[item])
        @test length(f.terms) == n_bins
        @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_unique[item]) == MOI.EqualTo(1)

        for bin in 1:n_bins
            t = f.terms[bin]
            @test t.coefficient === 1
            @test t.variable_index == bridge.assign_var[i]

            i += 1
        end
    end

    # Relation between the integer and binary representation of bin assignment.
    @test length(bridge.assign_number) == n_items
    i = 1
    for item in 1:n_items
        @test MOI.is_valid(model, bridge.assign_number[item])
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_number[item])
        @test length(f.terms) == n_bins + 1
        @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_number[item]) == MOI.EqualTo(0)

        t = f.terms[1]
        @test t.coefficient === -1
        @test t.variable_index == ((item == 1) ? x_bin_1 : x_bin_2)

        for bin in 1:n_bins
            t = f.terms[1 + bin]
            @test t.coefficient === bin
            @test t.variable_index == bridge.assign_var[i]

            i += 1
        end
    end

    # Load.
    @test length(bridge.assign_load) == n_bins
    for bin in 1:n_bins
        i = 1
        @test MOI.is_valid(model, bridge.assign_load[bin])
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_load[bin])
        @test length(f.terms) == n_items + 1
        @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_load[bin]) == MOI.EqualTo(0)

        @show f

        t = f.terms[1]
        @test t.coefficient === -1
        @test t.variable_index == ((bin == 1) ? x_load : nothing)

        for item in 1:n_items
            t = f.terms[1 + item]
            @test t.coefficient === weights[item]
            @test t.variable_index == bridge.assign_var[i]

            i += 1
        end
    end
end
