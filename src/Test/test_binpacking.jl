function test_binpacking_vectorofvariables(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2, x3
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorOfVariables, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}) # c1

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    w1 = T(2)
    w2 = T(2)

    c1 = MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x1, x2, x3]),
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [w1, w2]),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, c1)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 4
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 0
        @test MOI.get(model, MOI.VariablePrimal(), x3) == 0
    end
end

function MOIT.setup_test(
    ::typeof(test_binpacking_vectorofvariables),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[4, 0, 0]),
    )
    return
end

function test_binpacking_scalaraffinefunction(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2, x3
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorAffineFunction{T}, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}) # c1

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    w1 = T(2)
    w2 = T(2)

    c1 = MOI.add_constraint(
        model,
        MOIU.vectorize(one(T) .* [x1, x2, x3]),
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [w1, w2]),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, c1)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 4
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 0
        @test MOI.get(model, MOI.VariablePrimal(), x3) == 0
    end
end

function MOIT.setup_test(
    ::typeof(test_binpacking_scalaraffinefunction),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[4, 0, 0]),
    )
    return
end

# @testset "BinPacking: ScalarAffineFunction with variable sizes" begin
#     model = OPTIMIZER
#     MOI.empty!(model)

#     @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
#     @test MOI.supports_constraint(model, MOI.ScalarAffineFunction{Int}, MOI.EqualTo{Int})
#     @test MOI.supports_constraint(model, MOI.VectorAffineFunction{Int}, CP.BinPacking)

#     x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     x4, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     x5, _ = MOI.add_constrained_variable(model, MOI.Integer())

#     c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1], [x4]), 0), MOI.EqualTo(2))
#     c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1], [x5]), 0), MOI.EqualTo(2))

# TODO: currently, throws an assertion. https://github.com/dourouc05/ConstraintProgrammingExtensions.jl/issues/4
#     @test_throws(
#         MOI.AddConstraintNotAllowed{MOI.VectorAffineFunction{Int64}, CP.BinPacking},
#         MOI.add_constraint(model, 
#                            MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1, 2, 3, 4, 5], MOI.ScalarAffineTerm.([1, 1, 1, 1, 1], [x1, x2, x3, x4, x5])), [0, 0, 0, 0, 0]), 
#                            CP.BinPacking(1, 2))
#     )
# end
