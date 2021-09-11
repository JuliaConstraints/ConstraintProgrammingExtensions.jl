@testset "True and False" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.Config()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [0])),
    )
    COIT.truefalsetest(mock, config)
end

function true_test(model::MOI.ModelLike, config::MOIT.Config)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.EqualTo{Int})
    @test MOI.supports_constraint(model, MOI.VectorOfVariables, CP.True)

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(
        model,
        _vov([x1, x1]),
        CP.IfThenElse(CP.True(), MOI.EqualTo(1), MOI.EqualTo(0)),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, c1)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 1
    end
end

function false_test(model::MOI.ModelLike, config::MOIT.Config)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.EqualTo{Int})
    @test MOI.supports_constraint(model, MOI.VectorOfVariables, CP.False)

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(
        model,
        _vov([x1, x1]),
        CP.IfThenElse(CP.False(), MOI.EqualTo(1), MOI.EqualTo(0)),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, c1)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 0
    end
end

const truefalsetests = Dict("true" => true_test, "false" => false_test)

MOIT.@moitestset truefalse
