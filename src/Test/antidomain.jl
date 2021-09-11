function antidomain_singlevariable_test(
    model::MOI.ModelLike,
    config::MOIT.Config,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Interval{Int})
    @test MOI.supports_constraint(model, MOI.VariableIndex, CP.AntiDomain{Int})
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{Int})

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, x2, MOI.GreaterThan(1))
    c3 = MOI.add_constraint(model, x2, MOI.LessThan(3))
    c4 = MOI.add_constraint(model, MOI.VectorOfVariables([x1, x2]), CP.AllDifferent(2))

    c5 = MOI.add_constraint(model, x2, CP.AntiDomain(Set([3])))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)
    @test MOI.is_valid(model, c4)
    @test MOI.is_valid(model, c5)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

function antidomain_scalaraffinefunction_test(
    model::MOI.ModelLike,
    config::MOIT.Config,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        CP.Domain{Int},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{Int},
        CP.AllDifferent,
    )
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.EqualTo{Int},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, x2, MOI.GreaterThan(1))
    c3 = MOI.add_constraint(model, x2, MOI.LessThan(3))
    c4 = MOI.add_constraint(model, MOIU.vectorize(1 * MOI.VariableIndex.([x1, x2])), CP.AllDifferent(2))

    c5 = MOI.add_constraint(
        model,
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1], [x2]), 0),
        CP.AntiDomain(Set([3])),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)
    @test MOI.is_valid(model, c4)
    @test MOI.is_valid(model, c5)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

const antidomaintests = Dict(
    "antidomain_singlevariable" => antidomain_singlevariable_test,
    "antidomain_scalaraffinefunction" =>
        antidomain_scalaraffinefunction_test,
)

MOIT.@moitestset antidomain
