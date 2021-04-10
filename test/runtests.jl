using MathOptInterface, ConstraintProgrammingExtensions

using Test

const CP = ConstraintProgrammingExtensions
const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities

@testset "ConstraintProgrammingExtensions" begin
    include("sets.jl")
end
