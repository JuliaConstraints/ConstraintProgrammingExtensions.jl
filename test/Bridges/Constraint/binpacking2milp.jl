@testset "BinPacking2MILP: vector of variables, $(n_bins) bin, 2 items" for n_bins in [1, 2]
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
    weights = [3, 2]
    
    if n_bins == 1
        x_load_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
        x_load_2 = nothing
    elseif n_bins == 2
        x_load_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
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
    c = MOI.add_constraint(model, fct, CP.BinPacking(n_bins, n_items, weights))

    @test MOI.is_valid(model, x_load_1)
    if n_bins >= 2
        @test MOI.is_valid(model, x_load_2)
    end
    @test MOI.is_valid(model, x_bin_1)
    @test MOI.is_valid(model, x_bin_2)
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.BinPacking{Int}}(-1)]

    @testset "Bridge properties" begin
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        @test MOIB.added_constraint_types(typeof(bridge)) == [(MOI.ScalarAffineFunction{Int}, MOI.EqualTo{Int})]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == n_bins * n_items
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == n_bins * n_items
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{Int}, MOI.EqualTo{Int}}()) == n_bins + 2 * n_items

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == vec(bridge.assign_var)
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}()) == vec(bridge.assign_con)
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{Int}, MOI.EqualTo{Int}}()) == [bridge.assign_unique..., bridge.assign_number..., bridge.assign_load...]
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
            @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_unique[item]) == MOI.EqualTo(1)

            for bin in 1:n_bins
                t = f.terms[bin]
                @test t.coefficient === 1
                @test t.variable_index == bridge.assign_var[item, bin]
            end
        end
    end

    @testset "Relation between the integer and binary representation of bin assignment" begin
        @test length(bridge.assign_number) == n_items
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
                @test t.variable_index == bridge.assign_var[item, bin]
            end
        end
    end

    @testset "Load" begin
        @test length(bridge.assign_load) == n_bins
        for bin in 1:n_bins
            @test MOI.is_valid(model, bridge.assign_load[bin])
            f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_load[bin])
            @test length(f.terms) == n_items + 1
            @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_load[bin]) == MOI.EqualTo(0)

            t = f.terms[1]
            @test t.coefficient === -1
            @test t.variable_index == ((bin == 1) ? x_load_1 : x_load_2)

            for item in 1:n_items
                t = f.terms[1 + item]
                @test t.coefficient === weights[item]
                @test t.variable_index == bridge.assign_var[item, bin]
            end
        end
    end
end

# @testset "BinPacking2MILP: vector affine function, $(n_bins) bin, 2 items" for n_bins in [1, 2]
#     mock = MOIU.MockOptimizer(MILPModel{Int}())
#     model = COIB.BinPacking2MILP{Int}(mock)

#     @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
#     @test MOI.supports_constraint(
#         model,
#         MOI.ScalarAffineFunction{Int},
#         MOI.EqualTo{Int},
#     )
#     @test MOIB.supports_bridging_constraint(
#         model,
#         MOI.VectorOfVariables,
#         CP.BinPacking{Int},
#     )

#     n_items = 2
#     weights = [3, 2]
    
#     if n_bins == 1
#         x_load_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
#         x_load_2 = nothing
#     elseif n_bins == 2
#         x_load_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
#         x_load_2, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     else
#         @assert false
#     end
#     x_bin_1, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     x_bin_2, _ = MOI.add_constrained_variable(model, MOI.Integer())

#     fct = if n_bins == 1
#         MOI.VectorAffineFunction(
#             MOI.VectorAffineTerm.(
#                 1:3, 
#                 MOI.ScalarAffineTerm.(zeros(Int, 3), [x_load_1, x_bin_1, x_bin_2])
#             ),
#             [0]
#         )
#     elseif n_bins == 2
#         MOI.VectorAffineFunction(
#             MOI.VectorAffineTerm.(
#                 1:4, 
#                 MOI.ScalarAffineTerm.(zeros(Int, 4), [x_load_1, x_load_2, x_bin_1, x_bin_2])
#             ),
#             [0, 0]
#         )
#     else
#         @assert false
#     end
#     c = MOI.add_constraint(model, fct, CP.BinPacking(n_bins, n_items, weights))

#     @test MOI.is_valid(model, x_load_1)
#     if n_bins >= 2
#         @test MOI.is_valid(model, x_load_2)
#     end
#     @test MOI.is_valid(model, x_bin_1)
#     @test MOI.is_valid(model, x_bin_2)
#     @test MOI.is_valid(model, c)

#     bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.BinPacking{Int}}(-1)]

#     @testset "Bridge properties" begin
#     end

#     @testset "Set of variables: one binary per item and per bin" begin
#         @test length(bridge.assign_var) == n_items * n_bins
#         for i in 1:(n_items * n_bins)
#             @test MOI.is_valid(model, bridge.assign_var[i])
#         end

#         @test length(bridge.assign_con) == n_items * n_bins
#         for i in 1:(n_items * n_bins)
#             @test MOI.is_valid(model, bridge.assign_con[i])
#             @test MOI.get(model, MOI.ConstraintFunction(), bridge.assign_con[i]).variable == bridge.assign_var[i]
#             @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_con[i]) == MOI.ZeroOne()
#         end
#     end

#     @testset "One bin per item" begin
#         @test length(bridge.assign_unique) == n_items
#         for item in 1:n_items
#             @test MOI.is_valid(model, bridge.assign_unique[item])
#             f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_unique[item])
#             @test length(f.terms) == n_bins
#             @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_unique[item]) == MOI.EqualTo(1)

#             for bin in 1:n_bins
#                 t = f.terms[bin]
#                 @test t.coefficient === 1
#                 @test t.variable_index == bridge.assign_var[item, bin]
#             end
#         end
#     end

#     @testset "Relation between the integer and binary representation of bin assignment" begin
#         @test length(bridge.assign_number) == n_items
#         for item in 1:n_items
#             @test MOI.is_valid(model, bridge.assign_number[item])
#             f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_number[item])
#             @test length(f.terms) == n_bins + 1
#             @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_number[item]) == MOI.EqualTo(0)

#             t = f.terms[1]
#             @test t.coefficient === -1
#             @test t.variable_index == ((item == 1) ? x_bin_1 : x_bin_2)

#             for bin in 1:n_bins
#                 t = f.terms[1 + bin]
#                 @test t.coefficient === bin
#                 @test t.variable_index == bridge.assign_var[item, bin]
#             end
#         end
#     end

#     @testset "Load" begin
#         @test length(bridge.assign_load) == n_bins
#         for bin in 1:n_bins
#             @test MOI.is_valid(model, bridge.assign_load[bin])
#             f = MOI.get(model, MOI.ConstraintFunction(), bridge.assign_load[bin])
#             @test length(f.terms) == n_items + 1
#             @test MOI.get(model, MOI.ConstraintSet(), bridge.assign_load[bin]) == MOI.EqualTo(0)

#             t = f.terms[1]
#             @test t.coefficient === -1
#             @test t.variable_index == ((bin == 1) ? x_load_1 : x_load_2)

#             for item in 1:n_items
#                 t = f.terms[1 + item]
#                 @test t.coefficient === weights[item]
#                 @test t.variable_index == bridge.assign_var[item, bin]
#             end
#         end
#     end
# end
