using MathOptInterface, ConstraintProgrammingExtensions

using Test

const CP = ConstraintProgrammingExtensions
const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities

@testset "ConstraintProgrammingExtensions" begin
    @testset "Sets and utilities" begin
        # isbits.
        @testset "AllDifferent" begin
            @test isbitstype(CP.AllDifferent)

            @test CP.AllDifferent(2) == CP.AllDifferent(2)
            @test CP.AllDifferent(2) != CP.AllDifferent(3)
            @test CP.AllDifferent(3) != CP.AllDifferent(2)

            @test MOI.dimension(CP.AllDifferent(3)) == 3
        end

        @testset "Strictly{$(Ssub)}" for Ssub in [MOI.LessThan, MOI.GreaterThan]
            @test CP.Strictly(Ssub(1)) == CP.Strictly(Ssub(1))
            @test CP.Strictly(Ssub(1)) != CP.Strictly(Ssub(2))
            @test CP.Strictly(Ssub(2)) == CP.Strictly(Ssub(2))
            @test CP.Strictly(Ssub(2)) != CP.Strictly(Ssub(1))

            @test MOI.constant(CP.Strictly(Ssub(3))) == 3
            @test MOI.dimension(CP.Strictly(Ssub(3))) == 1
            @test MOIU.shift_constant(CP.Strictly(Ssub(3)), 1) == CP.Strictly(Ssub(4))
        end

        @testset "DifferentFrom" begin
            @test isbitstype(CP.DifferentFrom{Float64})

            @test CP.DifferentFrom(1) == CP.DifferentFrom(1)
            @test CP.DifferentFrom(1) != CP.DifferentFrom(2)
            @test CP.DifferentFrom(2) == CP.DifferentFrom(2)
            @test CP.DifferentFrom(2) != CP.DifferentFrom(1)

            @test MOI.constant(CP.DifferentFrom(3)) == 3
            @test MOI.dimension(CP.DifferentFrom(3)) == 1
            @test MOIU.shift_constant(CP.DifferentFrom(3), 1) == CP.DifferentFrom(4)
        end

        # Not isbits. Also test copying.
        # TODO.
    end
end
