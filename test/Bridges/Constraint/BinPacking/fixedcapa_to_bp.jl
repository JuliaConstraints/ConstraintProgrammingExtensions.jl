@testset "FixedCapacityBinPacking2BinPacking: $(fct_type), $(n_bins) bin, 2 items, $(T)" for fct_type in ["vector of variables", "vector affine function"], n_bins in [1, 2], T in [Int, Float64]
    mock = MOIU.MockOptimizer(BinPackingModel{T}())
    model = COIB.FixedCapacityBinPacking2BinPacking{T}(mock)

    if T == Int
        @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    end
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorOfVariables,
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.BinPacking{CP.FIXED_CAPACITY_BINPACKING, T},
    )

    n_items = 2
    weights = T[3, 2]
    capas = T[5, 6][1:n_bins]
    
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
    c = MOI.add_constraint(model, fct, CP.BinPacking{CP.FIXED_CAPACITY_BINPACKING}(n_bins, n_items, weights, capas))

    @test MOI.is_valid(model, x_load_1)
    if n_bins >= 2
        @test MOI.is_valid(model, x_load_2)
    end
    @test MOI.is_valid(model, x_bin_1)
    @test MOI.is_valid(model, x_bin_2)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.BinPacking{CP.FIXED_CAPACITY_BINPACKING, T}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.BinPacking{CP.FIXED_CAPACITY_BINPACKING, T}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        @test Set(MOIB.added_constraint_types(typeof(bridge))) == Set([
            (MOI.VectorAffineFunction{T}, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}),
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        ])

        @test MOI.get(bridge, MOI.NumberOfVariables()) == zero(T)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == n_bins
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}}()) == 1

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == bridge.capa
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}}()) == [bridge.bp]
    end

    @testset "BinPacking constraint" begin
        @test MOI.is_valid(model, bridge.bp)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.bp)
        @test length(f.terms) == n_items + n_bins
        for i in 1:n_items + n_bins
            @test f.terms[i].output_index == i
            @test f.terms[i].scalar_term.coefficient == 1
        end
        @test f.terms[1].scalar_term.variable == x_load_1
        if n_bins == 1
            @test f.terms[2].scalar_term.variable == x_bin_1
            @test f.terms[3].scalar_term.variable == x_bin_2
        elseif n_bins == 2
            @test f.terms[2].scalar_term.variable == x_load_2
            @test f.terms[3].scalar_term.variable == x_bin_1
            @test f.terms[4].scalar_term.variable == x_bin_2
        else
            @assert false
        end
        @test MOI.get(model, MOI.ConstraintSet(), bridge.bp) == CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(n_bins, n_items, weights)
    end

    @testset "Capacity constraints" begin
        @test length(bridge.capa) == n_bins
        for i in 1:n_bins
            @test MOI.is_valid(model, bridge.capa[i])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.capa[i])
            @test length(f.terms) == 1
            @test f.terms[1].coefficient == 1
            @test f.terms[1].variable == ((i == 1) ? x_load_1 : x_load_2)
            @test MOI.get(model, MOI.ConstraintSet(), bridge.capa[i]) == MOI.LessThan(capas[i])
        end
    end
end
