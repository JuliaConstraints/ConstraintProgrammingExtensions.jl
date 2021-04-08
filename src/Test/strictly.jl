function strictly_lessthan_singlevariable_test(model::MOI.ModelLike, config::MOIT.TestConfig)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.SingleVariable, CP.Domain{Int})
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        CP.Strictly{MOI.LessThan{Int}, Int},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, CP.Domain(Set([1, 2])))
    c2 = MOI.add_constraint(model, x2, MOI.EqualTo(2))

    c3 = MOI.add_constraint(
        model,
        _saf([1, -1], [x1, x2]),
        CP.Strictly(MOI.LessThan(0)),
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
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

function strictly_greaterthan_singlevariable_test(model::MOI.ModelLike, config::MOIT.TestConfig)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.SingleVariable, CP.Domain{Int})
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        CP.Strictly{MOI.GreaterThan{Int}, Int},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, CP.Domain(Set([1, 2])))
    c2 = MOI.add_constraint(model, x2, MOI.EqualTo(2))

    c3 = MOI.add_constraint(
        model,
        _saf([-1, 1], [x1, x2]),
        CP.Strictly(MOI.GreaterThan(0)),
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
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

const strictlytests = Dict(
    "strictly_lessthan_singlevariable" => strictly_lessthan_singlevariable_test,
    "strictly_greaterthan_singlevariable" => strictly_greaterthan_singlevariable_test,
)

@MOIT.moitestset strictly
