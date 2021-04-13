println(macroexpand(Utilities, @MOIU.model(
    Model,
    (MOI.ZeroOne, MOI.Integer),
    (
        MOI.EqualTo,
        MOI.GreaterThan,
        MOI.LessThan,
        MOI.Interval,
        MOI.Semicontinuous,
        MOI.Semiinteger,
    ),
    (
        MOI.Reals,
        MOI.Zeros,
        MOI.Nonnegatives,
        MOI.Nonpositives,
        MOI.Complements,
        MOI.NormInfinityCone,
        MOI.NormOneCone,
        MOI.SecondOrderCone,
        MOI.RotatedSecondOrderCone,
        MOI.GeometricMeanCone,
        MOI.ExponentialCone,
        MOI.DualExponentialCone,
        MOI.RelativeEntropyCone,
        MOI.NormSpectralCone,
        MOI.NormNuclearCone,
        MOI.PositiveSemidefiniteConeTriangle,
        MOI.PositiveSemidefiniteConeSquare,
        MOI.RootDetConeTriangle,
        MOI.RootDetConeSquare,
        MOI.LogDetConeTriangle,
        MOI.LogDetConeSquare,
        CP.AllDifferent,
        CP.AllDifferentExceptConstant,
        CP.AntiDomain,
        CP.BinPacking,
        CP.Count,
        CP.CountDistinct,
        CP.DifferentFrom,
        CP.Domain,
    ),
    (
        MOI.PowerCone,
        MOI.DualPowerCone,
        MOI.SOS1,
        MOI.SOS2,
    ),
    (),
    (MOI.ScalarAffineFunction,),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction,)
)))

@doc raw"""

An implementation of `ModelLike` that supports all functions and sets defined
in COI. It is parameterized by the coefficient type.

# Examples
```jl
model = Model{Float64}()
x = add_variable(model)
```
"""
Model