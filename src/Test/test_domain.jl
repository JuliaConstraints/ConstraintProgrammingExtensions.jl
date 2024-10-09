function test_domain_singlevariable(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @show model
    @show MOI.supports_add_constrained_variable(model, MOI.Integer) # x1, x2
    @show MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2
    @show MOI.supports_constraint(model, MOI.VariableIndex, CP.Domain{T}) # c1, c2
    @show MOI.supports_constraint(model, MOI.VectorOfVariables, MOI.AllDifferent) # c3
    @show MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{T}) # c4

    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, CP.Domain{T}) # c1, c2
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorOfVariables, MOI.AllDifferent) # c3
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{T}) # c4

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, CP.Domain(Set([1, 2])))
    c2 = MOI.add_constraint(model, x2, CP.Domain(Set([1, 2])))

    c3 = MOI.add_constraint(model, MOIU.vectorize([x1, x2]), MOI.AllDifferent(2))
    c4 = MOI.add_constraint(model, x1, MOI.EqualTo(1))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
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
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

function MOIT.setup_test(
    ::typeof(test_domain_singlevariable),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 2]),
    )
    return
end

function test_domain_scalaraffinefunction(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2
    @MOIT.requires MOI.supports_constraint(model, MOI.ScalarAffineFunction{T}, CP.Domain{T}) # c1, c2
    @MOIT.requires MOI.supports_constraint(model, MOI.VectorAffineFunction{T}, MOI.AllDifferent) # c3
    @MOIT.requires MOI.supports_constraint(model, MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}) # c4

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(
        model,
        one(T) * x1,
        CP.Domain(Set([1, 2])),
    )
    c2 = MOI.add_constraint(
        model,
        one(T) * x2,
        CP.Domain(Set([1, 2])),
    )

    c3 = MOI.add_constraint(
        model,
        MOIU.vectorize(one(T) .* [x1, x2]),
        MOI.AllDifferent(2),
    )
    c4 = MOI.add_constraint(
        model,
        one(T) * x1,
        MOI.EqualTo(1),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
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
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

function MOIT.setup_test(
    ::typeof(test_domain_scalaraffinefunction),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[1, 2]),
    )
    return
end
