function lexicographicallylessthan_vectorofvariables_test(
    model::MOI.ModelLike,
    config::MOIT.Config,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.EqualTo{Int})
    @test MOI.supports_constraint(
        model,
        MOI.VectorOfVariables,
        CP.LexicographicallyLessThan,
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x4, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(2))
    c2 = MOI.add_constraint(model, x2, MOI.GreaterThan(1))
    c3 = MOI.add_constraint(model, x3, MOI.EqualTo(2))
    c4 = MOI.add_constraint(model, x4, MOI.EqualTo(2))

    c5 = MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x1, x2, x3, x4]),
        CP.LexicographicallyLessThan(2),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, x4)
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
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 2
        @test MOI.get(model, MOI.VariablePrimal(), x2) in [1, 2]
        @test MOI.get(model, MOI.VariablePrimal(), x3) == 2
        @test MOI.get(model, MOI.VariablePrimal(), x4) == 2
    end
end

function lexicographicallylessthan_vectoraffinefunction_test(
    model::MOI.ModelLike,
    config::MOIT.Config,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.EqualTo{Int})
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{Int},
        CP.LexicographicallyLessThan,
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x4, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(2))
    c2 = MOI.add_constraint(model, x2, MOI.GreaterThan(1))
    c3 = MOI.add_constraint(model, x3, MOI.EqualTo(2))
    c4 = MOI.add_constraint(model, x4, MOI.EqualTo(2))

    c5 = MOI.add_constraint(
        model,
        MOIU.vectorize(MOI.SingleVariable.([x1, x2, x3, x4])),
        CP.LexicographicallyLessThan(2),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, x4)
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
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 2
        @test MOI.get(model, MOI.VariablePrimal(), x2) in [1, 2]
        @test MOI.get(model, MOI.VariablePrimal(), x3) == 2
        @test MOI.get(model, MOI.VariablePrimal(), x4) == 2
    end
end

const lexicographicallytests = Dict(
    "lexicographicallylessthan_vectorofvariables" =>
        lexicographicallylessthan_vectorofvariables_test,
    "lexicographicallylessthan_vectoraffinefunction" =>
        lexicographicallylessthan_vectoraffinefunction_test,
)

MOIT.@moitestset lexicographically
