function test_true(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorOfVariables, CP.IfThenElse{CP.True, MOI.EqualTo{T}, MOI.EqualTo{T}}) # c1

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x1, x1]),
        CP.IfThenElse(CP.True(), MOI.EqualTo(1), MOI.EqualTo(0)),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, c1)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
    end
end

function MOIT.setup_test(
    ::typeof(test_true),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1]),
    )
    return
end

function test_false(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorOfVariables, CP.IfThenElse{CP.False, MOI.EqualTo{T}, MOI.EqualTo{T}}) # c1

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x1, x1]),
        CP.IfThenElse(CP.False(), MOI.EqualTo(1), MOI.EqualTo(0)),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, c1)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 0
    end
end

function MOIT.setup_test(
    ::typeof(test_false),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[0]),
    )
    return
end
