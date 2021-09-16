function test_countdistinct_vectorofvariables(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2, x3, x4
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{T}) # c1, c2, c3
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorOfVariables, CP.CountDistinct) # c4

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x4, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, x2, MOI.EqualTo(1))
    c3 = MOI.add_constraint(model, x3, MOI.EqualTo(2))

    c4 = MOI.add_constraint(model, MOI.VectorOfVariables([x4, x1, x2, x3]), CP.CountDistinct(3))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, x4)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)
    @test MOI.is_valid(model, c4)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x3) == 2
        @test MOI.get(model, MOI.VariablePrimal(), x4) == 2
    end
end

function MOIT.setup_test(
    ::typeof(test_countdistinct_vectorofvariables),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 1, 2, 2]),
    )
    return
end

function test_countdistinct_vectoraffinefunction(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2, x3, x4
    @MOIT.requires MOI.supports_constraint(model, MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}) # c1, c2, c3
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorAffineFunction{T}, CP.CountDistinct) # c4

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x4, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, one(T) * x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, one(T) * x2, MOI.EqualTo(1))
    c3 = MOI.add_constraint(model, one(T) * x3, MOI.EqualTo(2))

    c4 = MOI.add_constraint(model, MOIU.vectorize(one(T) .* [x4, x1, x2, x3]), CP.CountDistinct(3))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, x4)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)
    @test MOI.is_valid(model, c4)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x3) == 2
        @test MOI.get(model, MOI.VariablePrimal(), x4) == 2
    end
end

function MOIT.setup_test(
    ::typeof(test_countdistinct_vectoraffinefunction),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 1, 2, 2]),
    )
    return
end
