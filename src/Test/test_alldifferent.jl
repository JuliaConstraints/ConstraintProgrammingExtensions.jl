function test_alldifferent_vectorofvariables(
    model::MOI.ModelLike,
    config::MOIT.Config,
)
    @requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2
    @requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.EqualTo{Int}) # c1
    @requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Interval{Int}) # c2
    @requires MOI.supports_constraint(model, MOI.VectorOfVariables, CP.AllDifferent) # c3

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.EqualTo(1))
    c2 = MOI.add_constraint(model, x2, MOI.Interval(1, 2))

    c3 = MOI.add_constraint(model, MOI.VectorOfVariables([x1, x2]), CP.AllDifferent(2))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)

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

function test_alldifferent_vectoraffinefunction(
    model::MOI.ModelLike,
    config::MOIT.Config,
    )
    @requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer) # x1, x2
    @requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Interval{Int}) # c1, c2
    @requires MOI.supports_constraint(model, MOI.VectorAffineFunction{Int}, CP.AllDifferent) # c3
    @requires MOI.supports_constraint(model, MOI.ScalarAffineFunction{Int}, MOI.EqualTo{Int}) # c4

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(model, x1, MOI.Interval(1, 2))
    c2 = MOI.add_constraint(model, x2, MOI.Interval(1, 2))

    c3 = MOI.add_constraint(model, MOIU.vectorize(1 .* [x1, x2]), CP.AllDifferent(2))
    c4 = MOI.add_constraint(model, 1 * x1, MOI.EqualTo(1))

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, c1)
    @test MOI.is_valid(model, c2)
    @test MOI.is_valid(model, c3)
    @test MOI.is_valid(model, c4)

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
