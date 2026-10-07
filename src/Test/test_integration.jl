function test_integration_map_colouring(
    model::MOI.ModelLike,
    config::MOIT.Config{T},
) where {T <: Real}
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @MOIT.requires MOI.supports_constraint(model, MOI.VariableIndex, MOI.Interval{T})
    @MOIT.requires MOI.supports_constraint(model, MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T})

    belgium, _ = MOI.add_constrained_variable(model, MOI.Integer())
    denmark, _ = MOI.add_constrained_variable(model, MOI.Integer())
    france, _ = MOI.add_constrained_variable(model, MOI.Integer())
    germany, _ = MOI.add_constrained_variable(model, MOI.Integer())
    luxembourg, _ = MOI.add_constrained_variable(model, MOI.Integer())
    netherlands, _ = MOI.add_constrained_variable(model, MOI.Integer())

    MOI.add_constraint(model, belgium, MOI.Interval(0, 3))
    MOI.add_constraint(model, denmark, MOI.Interval(0, 3))
    MOI.add_constraint(model, france, MOI.Interval(0, 3))
    MOI.add_constraint(model, germany, MOI.Interval(0, 3))
    MOI.add_constraint(model, luxembourg, MOI.Interval(0, 3))
    MOI.add_constraint(model, netherlands, MOI.Interval(0, 3))

    countries(c1, c2) = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, -1], [c1, c2]), 0)
    MOI.add_constraint(model, countries(belgium, france), CP.DifferentFrom(0))
    MOI.add_constraint(model, countries(belgium, germany), CP.DifferentFrom(0))
    MOI.add_constraint(model, countries(belgium, netherlands), CP.DifferentFrom(0))
    MOI.add_constraint(model, countries(belgium, luxembourg), CP.DifferentFrom(0))
    MOI.add_constraint(model, countries(denmark, germany), CP.DifferentFrom(0))
    MOI.add_constraint(model, countries(france, germany), CP.DifferentFrom(0))
    MOI.add_constraint(model, countries(france, luxembourg), CP.DifferentFrom(0))
    MOI.add_constraint(model, countries(germany, luxembourg), CP.DifferentFrom(0))
    MOI.add_constraint(model, countries(germany, netherlands), CP.DifferentFrom(0))

    if MOIT._supports(config, MOI.optimize!)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), belgium) != MOI.get(model, MOI.VariablePrimal(), france)
        @test MOI.get(model, MOI.VariablePrimal(), belgium) != MOI.get(model, MOI.VariablePrimal(), germany)
        @test MOI.get(model, MOI.VariablePrimal(), belgium) != MOI.get(model, MOI.VariablePrimal(), netherlands)
        @test MOI.get(model, MOI.VariablePrimal(), belgium) != MOI.get(model, MOI.VariablePrimal(), luxembourg)
        @test MOI.get(model, MOI.VariablePrimal(), denmark) != MOI.get(model, MOI.VariablePrimal(), germany)
        @test MOI.get(model, MOI.VariablePrimal(), france) != MOI.get(model, MOI.VariablePrimal(), germany)
        @test MOI.get(model, MOI.VariablePrimal(), france) != MOI.get(model, MOI.VariablePrimal(), luxembourg)
        @test MOI.get(model, MOI.VariablePrimal(), germany) != MOI.get(model, MOI.VariablePrimal(), luxembourg)
        @test MOI.get(model, MOI.VariablePrimal(), germany) != MOI.get(model, MOI.VariablePrimal(), netherlands)
    end
end

function MOIT.setup_test(
    ::typeof(test_integration_map_colouring),
    mock::MOIU.MockOptimizer,
    ::Config{T},
) where {T <: Real}
    # One feasible solution (among the many).
    belgium = 1
    denmark = 2
    france = 0
    germany = 3
    luxembourg = 2
    netherlands = 2

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> MOIU.mock_optimize!(mock, T[belgium, denmark, france, germany, luxembourg, netherlands]),
    )
    return
end
