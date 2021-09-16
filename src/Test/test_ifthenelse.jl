function test_ifthenelse_singlevariable(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2, x3
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{T}) # c1
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorOfVariables, CP.IfThenElse{MOI.EqualTo{T}, MOI.EqualTo{T}, MOI.EqualTo{T}}) # c2

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x1, x2, x3]),
        CP.IfThenElse(MOI.EqualTo(1), MOI.EqualTo(1), MOI.EqualTo(0)),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 1
    end
end

function MOIT.setup_test(
    ::typeof(test_ifthenelse_singlevariable),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 1, 0]),
    )
    return
end

function test_ifthenelse_scalaraffinefunction(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2, x3
    @MOIT.requires MOI.supports_constraint(model, MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}) # c1
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorAffineFunction{T}, CP.IfThenElse{MOI.EqualTo{T}, MOI.EqualTo{T}, MOI.EqualTo{T}}) # c2

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, 1 * x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(
        model,
        MOIU.vectorize([x1, x2, x3]),
        CP.IfThenElse(MOI.EqualTo(1), MOI.EqualTo(1), MOI.EqualTo(0)),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 1
    end
end

function MOIT.setup_test(
    ::typeof(test_ifthenelse_scalaraffinefunction),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 1, 0]),
    )
    return
end
