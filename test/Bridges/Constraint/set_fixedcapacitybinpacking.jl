@testset "FixedCapacityBinPacking2BinPacking" begin
    mock = MOIU.MockOptimizer(MILPModel{Int}())
    model = COIB.BinPacking2MILP{Int}(mock)

    @show model
    # @show MOIB.is_bridged(model, typeof(MOI.SingleVariable), typeof(MOI.Integer))
    @show MOIB.is_bridged(model, MOI.VectorOfVariables, CP.BinPacking{Int})
    # @show @which MOI.supports_constraint(typeof(model), typeof(MOI.SingleVariable), typeof(MOI.Integer))

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{Int},
        MOI.EqualTo{Int},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.BinPacking{Int},
    )
    
    x1, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x2, _ = MOI.add_constrained_variable(model, MOI.Integer())
    x3, _ = MOI.add_constrained_variable(model, MOI.Integer())

    c1 = MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x1, x2, x3]),
        CP.FixedCapacityBinPacking(1, 2, [2, 2], [2]),
    )

    @test MOI.is_valid(model, x1)
    @test MOI.is_valid(model, x2)
    @test MOI.is_valid(model, x3)
    @test MOI.is_valid(model, c1)
end
