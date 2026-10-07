@testset "Model" begin
    @testset "Optimiser attributes" begin
        m = CP.FlatZinc.Model()
        @test sprint(show, m) == "A FlatZinc (fzn) model"
    end

    @testset "Supported constraints" begin
        m = CP.FlatZinc.Model()

        @test MOI.supports(
            m,
	    MOI.ObjectiveFunction{MOI.VariableIndex}(),
        )
        @test MOI.supports_constraint(
            m,
            MOI.VariableIndex,
            MOI.LessThan{Int},
        )
        @test MOI.supports_constraint(
            m,
            MOI.VariableIndex,
            MOI.LessThan{Float64},
        )
        @test MOI.supports_constraint(
            m,
            MOI.VariableIndex,
            CP.Strictly{MOI.LessThan{Float64}},
        )
        @test MOI.supports_constraint(m, MOI.VariableIndex, CP.Domain{Int})
        @test MOI.supports_constraint(
            m,
            MOI.VariableIndex,
            MOI.Interval{Float64},
        )
        @test MOI.supports_constraint(
            m,
            MOI.VectorOfVariables,
            CP.Element{Int},
        )
        @test MOI.supports_constraint(
            m,
            MOI.VectorOfVariables,
            CP.Element{Bool},
        )
        @test MOI.supports_constraint(
            m,
            MOI.VectorOfVariables,
            CP.Element{Float64},
        )
        @test MOI.supports_constraint(
            m,
            MOI.VectorOfVariables,
            CP.MaximumAmong,
        )
        @test MOI.supports_constraint(
            m,
            MOI.VectorOfVariables,
            CP.MinimumAmong,
        )
        @test MOI.supports_constraint(
            m,
            MOI.ScalarAffineFunction{Int},
            MOI.EqualTo{Int},
        )
        @test MOI.supports_constraint(
            m,
            MOI.ScalarAffineFunction{Int},
            MOI.LessThan{Int},
        )
        @test MOI.supports_constraint(
            m,
            MOI.ScalarAffineFunction{Int},
            CP.DifferentFrom{Int},
        )
        @test MOI.supports_constraint(
            m,
            MOI.ScalarAffineFunction{Float64},
            MOI.EqualTo{Float64},
        )
        @test MOI.supports_constraint(
            m,
            MOI.ScalarAffineFunction{Float64},
            MOI.LessThan{Float64},
        )
        @test MOI.supports_constraint(
            m,
            MOI.ScalarAffineFunction{Float64},
            CP.Strictly{MOI.LessThan{Float64}},
        )
        @test MOI.supports_constraint(
            m,
            MOI.ScalarAffineFunction{Float64},
            CP.DifferentFrom{Float64},
        )
    end

    @testset "Supported constrained variable with $(S)" for S in [
        MOI.EqualTo{Float64},
        MOI.LessThan{Float64},
        MOI.Interval{Float64},
        MOI.EqualTo{Int},
        MOI.LessThan{Int},
        MOI.Interval{Int},
        MOI.EqualTo{Bool},
        MOI.ZeroOne,
        MOI.Integer,
    ]
        m = CP.FlatZinc.Model()
        @test MOI.supports_add_constrained_variable(m, S)
        @test MOI.supports_add_constrained_variables(m, S)
    end
end
