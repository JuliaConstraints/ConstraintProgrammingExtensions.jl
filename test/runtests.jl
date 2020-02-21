using MathOptInterface, ConstraintProgrammingExtensions

using Test

const CP = ConstraintProgrammingExtensions
const MOI = MathOptInterface

@testset "ConstraintProgrammingExtensions" begin
    @testset "Sets and utilities" begin
        # isbits.
        @testset "AllDifferent" begin
            @test isbitstype(CP.AllDifferent)

            @test CP.AllDifferent(2) == CP.AllDifferent(2)
            @test CP.AllDifferent(2) != CP.AllDifferent(3)
            @test CP.AllDifferent(3) != CP.AllDifferent(2)
        end

        @testset "Strictly{$(Ssub)}" for Ssub in [MOI.LessThan, MOI.GreaterThan]
            @test isbitstype(CP.Strictly{Ssub{Float64}})

            @test CP.Strictly(Ssub(1)) == CP.Strictly(Ssub(1))
            @test CP.Strictly(Ssub(1)) != CP.Strictly(Ssub(2))
            @test CP.Strictly(Ssub(2)) == CP.Strictly(Ssub(2))
            @test CP.Strictly(Ssub(2)) != CP.Strictly(Ssub(1))
        end

        @testset "DifferentFrom" begin
            @test isbitstype(CP.DifferentFrom{Float64})

            @test CP.DifferentFrom(1) == CP.DifferentFrom(1)
            @test CP.DifferentFrom(1) != CP.DifferentFrom(2)
            @test CP.DifferentFrom(2) == CP.DifferentFrom(2)
            @test CP.DifferentFrom(2) != CP.DifferentFrom(1)
        end

        # Not isbits.
        # TODO.
    end
end
