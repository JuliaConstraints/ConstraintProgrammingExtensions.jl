function test_antidomain_singlevariable(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{T}) # c1
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.GreaterThan{T}) # c2
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.LessThan{T}) # c3
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorOfVariables, MOI.AllDifferent) # c4
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, CP.AntiDomain{T}) # c5

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(T(1)))
    c2 = MOI.add_constraint(model, x2, MOI.GreaterThan(T(1)))
    c3 = MOI.add_constraint(model, x2, MOI.LessThan(T(3)))
    c4 = MOI.add_constraint(model, MOI.VectorOfVariables([x1, x2]), MOI.AllDifferent(2))

    c5 = MOI.add_constraint(model, x2, CP.AntiDomain(Set(T[3])))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)
    @test MOI.is_valid(model, c4)
    @test MOI.is_valid(model, c5)

    if MOIT._supports(config, MOI.optimize!)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMIZE_NOT_CALLED
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

function MOIT.setup_test(
    ::typeof(test_antidomain_singlevariable),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 2]),
    )
    return
end

function test_antidomain_scalaraffinefunction(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{Int}) # c1
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.GreaterThan{Int}) # c2
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.LessThan{Int}) # c3
    @MOIT.requires MOI.supports_constraint(model, MOI.ScalarAffineFunction{Int}, MOI.AllDifferent) # c4
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, CP.AntiDomain{Int}) # c5

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(T(1)))
    c2 = MOI.add_constraint(model, x2, MOI.GreaterThan(T(1)))
    c3 = MOI.add_constraint(model, x2, MOI.LessThan(T(3)))
    c4 = MOI.add_constraint(model, MOIU.vectorize(one(T) .* [x1, x2]), MOI.AllDifferent(2))

    c5 = MOI.add_constraint(
        model,
        one(T) * x2,
        CP.AntiDomain(Set([3])),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)
    @test MOI.is_valid(model, c4)
    @test MOI.is_valid(model, c5)

    if MOIT._supports(config, MOI.optimize!)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMIZE_NOT_CALLED
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

function MOIT.setup_test(
    ::typeof(test_antidomain_scalaraffinefunction),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 2]),
    )
    return
end
