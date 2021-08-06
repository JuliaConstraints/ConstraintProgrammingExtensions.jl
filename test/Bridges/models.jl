# -----------------------------------------------------------------------------
# - MILP and direct generalisations (like strict inequalities or indicators)
# -----------------------------------------------------------------------------

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

const StrictlyGreaterThan{T} = CP.Strictly{MOI.GreaterThan{T}, T}
const StrictlyLessThan{T} = CP.Strictly{MOI.LessThan{T}, T}

MOIU.@model(
    PseudoMILPModel,
    (),
    (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval, StrictlyGreaterThan, StrictlyLessThan),
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

const EqualToIndicatorOne{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}
const EqualToIndicatorZero{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, MOI.EqualTo{T}}
const GreaterThanIndicatorOne{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}
const GreaterThanIndicatorZero{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, MOI.GreaterThan{T}}
const LessThanIndicatorOne{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}
const LessThanIndicatorZero{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, MOI.LessThan{T}}
const StrictlyGreaterThanIndicatorOne{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.Strictly{MOI.GreaterThan{T}, T}}
const StrictlyGreaterThanIndicatorZero{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.GreaterThan{T}, T}}
const StrictlyLessThanIndicatorOne{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.Strictly{MOI.LessThan{T}, T}}
const StrictlyLessThanIndicatorZero{T} =
    MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.LessThan{T}, T}}

MOIU.@model(
    IndicatorMILPModel,
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
    (
        MOI.PowerCone, 
        MOI.DualPowerCone, 
        EqualToIndicatorOne, 
        EqualToIndicatorZero, 
        GreaterThanIndicatorOne, 
        GreaterThanIndicatorZero, 
        LessThanIndicatorOne, 
        LessThanIndicatorZero
    ),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    AbsoluteValueIndicatorPseudoMILPModel,
    (),
    (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval, StrictlyGreaterThan, StrictlyLessThan),
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
        CP.AbsoluteValue, 
    ),
    (
        MOI.PowerCone, 
        MOI.DualPowerCone, 
        EqualToIndicatorOne, 
        EqualToIndicatorZero, 
        GreaterThanIndicatorOne, 
        GreaterThanIndicatorZero, 
        LessThanIndicatorOne, 
        LessThanIndicatorZero,
        StrictlyGreaterThanIndicatorOne,
        StrictlyGreaterThanIndicatorZero,
        StrictlyLessThanIndicatorOne,
        StrictlyLessThanIndicatorZero,
    ),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    IndicatorPseudoMILPModel,
    (),
    (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval, StrictlyGreaterThan, StrictlyLessThan),
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
    (
        MOI.PowerCone, 
        MOI.DualPowerCone, 
        EqualToIndicatorOne, 
        EqualToIndicatorZero, 
        GreaterThanIndicatorOne, 
        GreaterThanIndicatorZero, 
        LessThanIndicatorOne, 
        LessThanIndicatorZero,
        StrictlyGreaterThanIndicatorOne,
        StrictlyGreaterThanIndicatorZero,
        StrictlyLessThanIndicatorOne,
        StrictlyLessThanIndicatorZero,
    ),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# -----------------------------------------------------------------------------
# - Generic CP constraints.
# -----------------------------------------------------------------------------

# All different.

MOIU.@model(
    AllDifferentIndexingModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.AllDifferent,
        CP.ElementVariableArray,
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    AllDifferentInverseModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.AllDifferent,
        CP.Inverse,
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Count.

MOIU.@model(
    CountModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.Count{MOI.EqualTo{Int}},
        CP.Count{MOI.EqualTo{Float64}},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Different from.

MOIU.@model(
    DifferentFromModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
        CP.DifferentFrom,
    ),
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

# Domain.

MOIU.@model(
    DomainModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
        CP.Domain,
    ),
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

# Lexicographically greater than.

MOIU.@model(
    LexicographicallyGreaterThanModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.LexicographicallyGreaterThan,
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    IntStrictlyLexicographicallyGreaterThanModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.Strictly{CP.LexicographicallyGreaterThan, Int},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    FloatStrictlyLexicographicallyGreaterThanModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.Strictly{CP.LexicographicallyGreaterThan, Float64},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Lexicographically less than.

MOIU.@model(
    LexicographicallyLessThanModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.LexicographicallyLessThan,
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    IntStrictlyLexicographicallyLessThanModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.Strictly{CP.LexicographicallyLessThan, Int},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    FloatStrictlyLexicographicallyLessThanModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.Strictly{CP.LexicographicallyLessThan, Float64},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Global cardinality (variable).

MOIU.@model(
    GlobalCardinalityVariableModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.GlobalCardinalityVariable,
        CP.Membership,
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Global cardinality.

MOIU.@model(
    GlobalCardinalityModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
        CP.Domain, 
    ),
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
    (MOI.PowerCone, MOI.DualPowerCone, CP.GlobalCardinality),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Imply.

MOIU.@model(
    ImplyModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.Imply{MOI.LessThan{Int}, MOI.LessThan{Int}},
        CP.Imply{MOI.LessThan{Float64}, MOI.LessThan{Float64}},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Indicators about different from.

MOIU.@model(
    FloatDifferentFromIndicatorMILPModel,
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
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{Float64}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{Float64}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{Float64}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.DifferentFrom{Float64}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, MOI.EqualTo{Float64}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, MOI.LessThan{Float64}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, MOI.GreaterThan{Float64}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{Float64}},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    IntDifferentFromIndicatorMILPModel,
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
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{Int}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{Int}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{Int}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.DifferentFrom{Int}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, MOI.EqualTo{Int}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, MOI.LessThan{Int}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, MOI.GreaterThan{Int}},
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{Int}},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Reification of equal-to.

MOIU.@model(
    FloatReificationEqualToModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
        CP.DifferentFrom,
    ),
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
        CP.Reification{MOI.EqualTo{Float64}},
        CP.Reification{CP.DifferentFrom{Float64}},
        CP.Reification{MOI.LessThan{Float64}},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    IntReificationEqualToModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
        CP.DifferentFrom,
    ),
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
        CP.Reification{MOI.EqualTo{Int}},
        CP.Reification{CP.DifferentFrom{Int}},
        CP.Reification{MOI.LessThan{Int}},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    DisjunctionModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.Disjunction{NTuple{2, MOI.LessThan{Int}}},
        CP.Disjunction{NTuple{2, MOI.LessThan{Float64}}},
        CP.Disjunction{NTuple{4, MOI.LessThan{Int}}},
        CP.Disjunction{NTuple{4, MOI.LessThan{Float64}}},
        CP.Disjunction{NTuple{6, MOI.LessThan{Int}}},
        CP.Disjunction{NTuple{6, MOI.LessThan{Float64}}},
        CP.Disjunction{NTuple{2, MOI.EqualTo{Int}}},
        CP.Disjunction{NTuple{2, MOI.EqualTo{Float64}}},
        CP.Disjunction{NTuple{4, MOI.EqualTo{Int}}},
        CP.Disjunction{NTuple{4, MOI.EqualTo{Float64}}},
        CP.Disjunction{NTuple{6, MOI.EqualTo{Int}}},
        CP.Disjunction{NTuple{6, MOI.EqualTo{Float64}}},
        CP.Disjunction{Tuple{CP.Domain{Int}, CP.Domain{Int}, CP.DifferentFrom{Int}}},
        CP.Disjunction{Tuple{CP.Domain{Float64}, CP.Domain{Float64}, CP.DifferentFrom{Float64}}},
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# -----------------------------------------------------------------------------
# - Higher-level CP functions.
# -----------------------------------------------------------------------------

# Absolute value.

MOIU.@model(
    AbsoluteValueModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.AbsoluteValue
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# -----------------------------------------------------------------------------
# - Higher-level CP constraints.
# -----------------------------------------------------------------------------

# Bin packing.

MOIU.@model(
    BinPackingModel,
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
    (MOI.PowerCone, MOI.DualPowerCone, CP.BinPacking),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    VariableCapacityBinPackingModel,
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
    (MOI.PowerCone, MOI.DualPowerCone, CP.VariableCapacityBinPacking),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Knapsack.

MOIU.@model(
    KnapsackModel,
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
    (MOI.PowerCone, MOI.DualPowerCone, CP.Knapsack),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

MOIU.@model(
    VariableCapacityKnapsackModel,
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
    (MOI.PowerCone, MOI.DualPowerCone, CP.VariableCapacityKnapsack),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Non-overlapping orthotopes.

MOIU.@model(
    ConditionallyNonOverlappingOrthotopesModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.ConditionallyNonOverlappingOrthotopes,
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Sorting.

MOIU.@model(
    SortPermutationModel,
    (),
    (
        MOI.EqualTo, 
        MOI.GreaterThan, 
        MOI.LessThan, 
        MOI.Interval, 
    ),
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
        CP.SortPermutation,
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)
