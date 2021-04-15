function differentfrom_singlevariable_test(
    model::MOI.ModelLike,
    config::MOIT.TestConfig,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Interval{Int})
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.EqualTo{Int})
    @test MOI.supports_constraint(
        model,
        MOI.SingleVariable,
        CP.DifferentFrom{Int},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.Interval(1, 2))

    c2 = MOI.add_constraint(model, x1, CP.DifferentFrom(2))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
    end
end

function differentfrom_scalaraffinefunction_test(
    model::MOI.ModelLike,
    config::MOIT.TestConfig,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Interval{Int})
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        CP.DifferentFrom{Int},
    )
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.EqualTo{Int},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.Interval(1, 2))
    c2 = MOI.add_constraint(model, x2, MOI.Interval(1, 2))

    c3 = MOI.add_constraint(model, _saf([1, -1], [x1, x2]), CP.DifferentFrom(0))
    c4 = MOI.add_constraint(model, _saf(x1), MOI.EqualTo(1))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)
    @test MOI.is_valid(model, c4)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

const differentfromtests = Dict(
    "differentfrom_singlevariable" => differentfrom_singlevariable_test,
    "differentfrom_scalaraffinefunction" =>
        differentfrom_scalaraffinefunction_test,
)

MOIT.@moitestset differentfrom
