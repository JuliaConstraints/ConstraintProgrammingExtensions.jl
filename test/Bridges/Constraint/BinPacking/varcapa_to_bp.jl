@testset "FixedCapacityBinPacking2BinPacking: vector of variables, $(n_bins) bin, 2 items" for n_bins in [1, 2]
    mock = MOIU.MockOptimizer(BinPackingModel{Int}())
    model = COIB.FixedCapacityBinPacking2BinPacking{Int}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.LessThan{Int},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorOfVariables,
        CP.BinPacking{Int},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.FixedCapacityBinPacking{Int},
    )

    n_items = 2
    weights = [3, 2]
    capas = [5, 6][1:n_bins]
    
    x_load_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    if n_bins == 1
        x_load_2 = nothing
    elseif n_bins == 2
        x_load_2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    else
        @assert false
    end
    x_bin_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x_bin_2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    fct = if n_bins == 1
        MOI.VectorOfVariables([x_load_1, x_bin_1, x_bin_2])
    elseif n_bins == 2
        MOI.VectorOfVariables([x_load_1, x_load_2, x_bin_1, x_bin_2])
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.FixedCapacityBinPacking(n_bins, n_items, weights, capas))

    @test MOI.is_valid(model, x_load_1)
    if n_bins >= 2
        @test MOI.is_valid(model, x_load_2)
    end
    @test MOI.is_valid(model, x_bin_1)
    @test MOI.is_valid(model, x_bin_2)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.FixedCapacityBinPacking{Int}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.FixedCapacityBinPacking{Int}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test Set(MOIB.added_constraint_types(typeof(bridge))) == Set([
            (MOI.VectorAffineFunction{Int}, CP.BinPacking{Int}),
            (MOI.ScalarAffineFunction{Int}, MOI.LessThan{Int}),
        ])

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{Int}, MOI.LessThan{Int}}()) == n_bins
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Int}, CP.BinPacking{Int}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{Int}, MOI.LessThan{Int}}()) == bridge.capa
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{Int}, CP.BinPacking{Int}}()) == [bridge.bp]
    end

    @testset "BinPacking constraint" begin
        @test MOI.is_valid(model, bridge.bp)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.bp)
        @test length(f.terms) == n_items + n_bins
        for i in 1:n_items + n_bins
            @test f.terms[i].output_index == i
            @test f.terms[i].scalar_term.coefficient == 1
        end
        @test f.terms[1].scalar_term.variable_index == x_load_1
        if n_bins == 1
            @test f.terms[2].scalar_term.variable_index == x_bin_1
            @test f.terms[3].scalar_term.variable_index == x_bin_2
        elseif n_bins == 2
            @test f.terms[2].scalar_term.variable_index == x_load_2
            @test f.terms[3].scalar_term.variable_index == x_bin_1
            @test f.terms[4].scalar_term.variable_index == x_bin_2
        else
            @assert false
        end
        @test MOI.get(model, MOI.ConstraintSet(), bridge.bp) == CP.BinPacking(n_bins, n_items, weights)
    end

    @testset "Capacity constraints" begin
        @test length(bridge.capa) == n_bins
        for i in 1:n_bins
            @test MOI.is_valid(model, bridge.capa[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.capa[i])
            @test length(f.terms) == 1
            @test f.terms[1].coefficient == 1
            @test f.terms[1].variable_index == ((i == 1) ? x_load_1 : x_load_2)
            @test MOI.get(model, MOI.ConstraintSet(), bridge.capa[i]) == MOI.LessThan(capas[i])
        end
    end
end

@testset "FixedCapacityBinPacking2BinPacking: vector affine function, $(n_bins) bin, 2 items" for n_bins in [1, 2]
    mock = MOIU.MockOptimizer(BinPackingModel{Int}())
    model = COIB.FixedCapacityBinPacking2BinPacking{Int}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.LessThan{Int},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorOfVariables,
        CP.BinPacking{Int},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.FixedCapacityBinPacking{Int},
    )

    n_items = 2
    weights = [3, 2]
    capas = [5, 6][1:n_bins]
    
    x_load_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    if n_bins == 1
        x_load_2 = nothing
    elseif n_bins == 2
        x_load_2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    else
        @assert false
    end
    x_bin_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x_bin_2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    fct = if n_bins == 1
        MOI.VectorAffineFunction(
            MOI.VectorAffineTerm.(
                1:3, 
                MOI.ScalarAffineTerm.(ones(Int, 3), [x_load_1, x_bin_1, x_bin_2])
            ),
            zeros(Int, 3)
        )
    elseif n_bins == 2
        MOI.VectorAffineFunction(
            MOI.VectorAffineTerm.(
                1:4, 
                MOI.ScalarAffineTerm.(ones(Int, 4), [x_load_1, x_load_2, x_bin_1, x_bin_2])
            ),
            zeros(Int, 4)
        )
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.FixedCapacityBinPacking(n_bins, n_items, weights, capas))

    @test MOI.is_valid(model, x_load_1)
    if n_bins >= 2
        @test MOI.is_valid(model, x_load_2)
    end
    @test MOI.is_valid(model, x_bin_1)
    @test MOI.is_valid(model, x_bin_2)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.FixedCapacityBinPacking{Int}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.FixedCapacityBinPacking{Int}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{DataType}[]
        @test Set(MOIB.added_constraint_types(typeof(bridge))) == Set([
            (MOI.VectorAffineFunction{Int}, CP.BinPacking{Int}),
            (MOI.ScalarAffineFunction{Int}, MOI.LessThan{Int}),
        ])

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{Int}, MOI.LessThan{Int}}()) == n_bins
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Int}, CP.BinPacking{Int}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{Int}, MOI.LessThan{Int}}()) == bridge.capa
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{Int}, CP.BinPacking{Int}}()) == [bridge.bp]
    end

    @testset "BinPacking constraint" begin
        @test MOI.is_valid(model, bridge.bp)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.bp)
        @test length(f.terms) == n_items + n_bins
        for i in 1:n_items + n_bins
            @test f.terms[i].output_index == i
            @test f.terms[i].scalar_term.coefficient == 1
        end
        @test f.terms[1].scalar_term.variable_index == x_load_1
        if n_bins == 1
            @test f.terms[2].scalar_term.variable_index == x_bin_1
            @test f.terms[3].scalar_term.variable_index == x_bin_2
        elseif n_bins == 2
            @test f.terms[2].scalar_term.variable_index == x_load_2
            @test f.terms[3].scalar_term.variable_index == x_bin_1
            @test f.terms[4].scalar_term.variable_index == x_bin_2
        else
            @assert false
        end
        @test MOI.get(model, MOI.ConstraintSet(), bridge.bp) == CP.BinPacking(n_bins, n_items, weights)
    end

    @testset "Capacity constraints" begin
        @test length(bridge.capa) == n_bins
        for i in 1:n_bins
            @test MOI.is_valid(model, bridge.capa[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.capa[i])
            @test length(f.terms) == 1
            @test f.terms[1].coefficient == 1
            @test f.terms[1].variable_index == ((i == 1) ? x_load_1 : x_load_2)
            @test MOI.get(model, MOI.ConstraintSet(), bridge.capa[i]) == MOI.LessThan(capas[i])
        end
    end
end
