function minimumdistance_vectorofvariables_test(
    model::MOI.ModelLike,
    config::MOIT.Config,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Interval{Int})
    @test MOI.supports_constraint(
        model,
        MOI.VectorOfVariables,
        CP.MinimumDistance{Int},
    )
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{Int})

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, x2, MOI.Interval(1, 2))

    c3 = MOI.add_constraint(model, MOIU.vectorize([x1, x2]), CP.MinimumDistance(2, 1))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

function minimumdistance_vectoraffinefunction_test(
    model::MOI.ModelLike,
    config::MOIT.Config,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Interval{Int})
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{Int},
        CP.MinimumDistance{Int},
    )
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.EqualTo{Int},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, x2, MOI.Interval(1, 2))

    c3 = MOI.add_constraint(model, MOIU.vectorize([x1, x2]), CP.MinimumDistance(2, 1))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 2
    end
end

const minimumdistancetests = Dict(
    "minimumdistance_vectorofvariables" =>
        minimumdistance_vectorofvariables_test,
    "minimumdistance_vectoraffinefunction" =>
        minimumdistance_vectoraffinefunction_test,
)

MOIT.@moitestset minimumdistance
