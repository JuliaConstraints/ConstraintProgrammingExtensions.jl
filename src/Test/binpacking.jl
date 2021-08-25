function binpacking_vectorofvariables_test(
    model::MOI.ModelLike,
    config::MOIT.TestConfig,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.EqualTo{Int},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorOfVariables,
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING, Int},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    w1 = 2
    w2 = 2

    c1 = MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x1, x2, x3]),
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [w1, w2]),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, c1)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 4
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 0
        @test MOI.get(model, MOI.VariablePrimal(), x3) == 0
    end
end

function binpacking_scalaraffinefunction_test(
    model::MOI.ModelLike,
    config::MOIT.TestConfig,
)
    MOI.empty!(model)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.EqualTo{Int},
    )
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{Int},
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING, Int},
    )

    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
    w1 = 2
    w2 = 2

    c1 = MOI.add_constraint(
        model,
        _vaf([x1, x2, x3]),
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(1, 2, [w1, w2]),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, c1)

    if config.solve
        MOI.optimize!(model)
        @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
        @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT

        @test MOI.get(model, MOI.ResultCount()) >= 1
        @test MOI.get(model, MOI.VariablePrimal(), x1) == 4
        @test MOI.get(model, MOI.VariablePrimal(), x2) == 0
        @test MOI.get(model, MOI.VariablePrimal(), x3) == 0
    end
end

# @testset "BinPacking: ScalarAffineFunction with variable sizes" begin
#     model = OPTIMIZER
#     MOI.empty!(model)

#     @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
#     @test MOI.supports_constraint(model, MOI.ScalarAffineFunction{Int}, MOI.EqualTo{Int})
#     @test MOI.supports_constraint(model, MOI.VectorAffineFunction{Int}, CP.BinPacking)

#     x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     x3, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     x4, _ = MOI.add_constrained_variable(model, MOI.Integer())
#     x5, _ = MOI.add_constrained_variable(model, MOI.Integer())

#     c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1], [x4]), 0), MOI.EqualTo(2))
#     c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1], [x5]), 0), MOI.EqualTo(2))

# TODO: currently, throws an assertion. https://github.com/dourouc05/ConstraintProgrammingExtensions.jl/issues/4
#     @test_throws(
#         MOI.AddConstraintNotAllowed{MOI.VectorAffineFunction{Int64}, CP.BinPacking},
#         MOI.add_constraint(model, 
#                            MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1, 2, 3, 4, 5], MOI.ScalarAffineTerm.([1, 1, 1, 1, 1], [x1, x2, x3, x4, x5])), [0, 0, 0, 0, 0]), 
#                            CP.BinPacking(1, 2))
#     )
# end

const binpackingtests = Dict(
    "binpacking_vectorofvariables" => binpacking_vectorofvariables_test,
    "binpacking_scalaraffinefunction" =>
        binpacking_scalaraffinefunction_test,
)

MOIT.@moitestset binpacking
