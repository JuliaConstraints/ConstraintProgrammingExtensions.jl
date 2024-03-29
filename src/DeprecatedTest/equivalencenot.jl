function equivalencenot_singlevariable_test(
    model::MOI.ModelLike,
    config::MOIT.Config,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{Int})
    @test MOI.supports_constraint(
        model,
        MOI.VectorOfVariables,
        CP.EquivalenceNot{MOI.EqualTo{Int}, MOI.EqualTo{Int}},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x1, x2]),
        CP.EquivalenceNot(MOI.EqualTo(1), MOI.EqualTo(1)),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) != 1
    end
end

function equivalencenot_scalaraffinefunction_test(
    model::MOI.ModelLike,
    config::MOIT.Config,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.EqualTo{Int},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{Int},
        CP.EquivalenceNot{MOI.EqualTo{Int}, MOI.EqualTo{Int}},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, 1 * x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(
        model,
        MOIU.vectorize([x1, x2]),
        CP.EquivalenceNot(MOI.EqualTo(1), MOI.EqualTo(1)),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) != 1
    end
end

const equivalencenottests = Dict(
    "equivalencenot_singlevariable" => equivalencenot_singlevariable_test,
    "equivalencenot_scalaraffinefunction" =>
        equivalencenot_scalaraffinefunction_test,
)

MOIT.@moitestset equivalencenot
