function test_indicator_singlevariable(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{T}) # c1
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorOfVariables, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}) # c2

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{Int})
    @test MOI.supports_constraint(
        model,
        MOI.VectorOfVariables,
        MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{Int}},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, MOI.VectorOfVariables([x1, x2]), MOI.Indicator{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo(2)))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

function MOIT.setup_test(
    ::typeof(test_indicator_singlevariable),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 2]),
    )
    return
end

function test_indicator_scalaraffinefunction(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2
    @MOIT.requires MOI.supports_constraint(model, MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}) # c1
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}) # c2

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, 1 * x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, MOIU.vectorize(one(T) .* [x1, x2]), MOI.Indicator{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo(2)))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

function MOIT.setup_test(
    ::typeof(test_indicator_scalaraffinefunction),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 2]),
    )
    return
end
