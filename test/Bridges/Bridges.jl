@testset "Bridges" begin
    MOIU.@model(
        MILPModel,
        (),
        (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval),
        (
            MOI.Zeros,
            MOI.Nonnegatives,
            MOI.Nonpositives,
            MOI.NormInfinityCone,
            MOI.NormOneCone,
            MOI.SecondOrderCone,
            MOI.RotatedSecondOrderCone,
            MOI.GeometricMeanCone,
            MOI.RelativeEntropyCone,
            MOI.NormSpectralCone,
            MOI.NormNuclearCone,
            MOI.PositiveSemidefiniteConeTriangle,
            MOI.ExponentialCone,
        ),
        (MOI.PowerCone, MOI.DualPowerCone),
        (),
        (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
        (MOI.VectorOfVariables,),
        (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
    )

    @testset "BinPacking" begin
        include("set_fixedcapacitybinpacking.jl")
    end
end