abstract type AbstractNonlinearScalarFunction <: MOI.AbstractScalarFunction end

# -----------------------------------------------------------------------------
# - Affine expressions of nonlinear terms, inspired by MOI.ScalarAffineFunction
# -----------------------------------------------------------------------------

struct NonlinearScalarAffineTerm{T}
    coefficient::T
    expr::AbstractNonlinearScalarFunction
end

struct NonlinearScalarAffineFunction{T} <: AbstractNonlinearScalarFunction
    terms::Vector{NonlinearScalarAffineTerm{T}}
    constant::T
end

# -----------------------------------------------------------------------------
# - Geometric programming
# -----------------------------------------------------------------------------

# Aka monomial.
# Division: exponent -1.0.
# Square root: exponent 0.5.
struct NonlinearScalarFactor{T}
    exponent::T
    expr::AbstractNonlinearScalarFunction
end

# Posynomial if the constant is > 0, signomial otherwise.
struct ProductFunction{T} <: AbstractNonlinearScalarFunction
    factors::Vector{NonlinearScalarFactor{T}}
    constant::T
end

# -----------------------------------------------------------------------------
# - Usual nonlinear combinations of functions
# -----------------------------------------------------------------------------

struct AbsoluteValueFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct ExponentialFunction{T} <: AbstractNonlinearScalarFunction
    exponent::T
    expr::AbstractNonlinearScalarFunction
end

function ExponentialFunction(expr::AbstractNonlinearScalarFunction)
    return ExponentialFunction{Float64}(ℯ, expr)
end

struct LogarithmFunction{T} <: AbstractNonlinearScalarFunction
    base::T
    expr::AbstractNonlinearScalarFunction
end

function LogarithmFunction(expr::AbstractNonlinearScalarFunction)
    return LogarithmFunction{Float64}(ℯ, expr)
end

# -----------------------------------------------------------------------------
# - Trigonometry
# -----------------------------------------------------------------------------

struct CosineFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct SineFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct TangentFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct ArcCosineFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct ArcSineFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct ArcTangentFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct HyperbolicCosineFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct HyperbolicSineFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct HyperbolicTangentFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct ArcHyperbolicCosineFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct ArcHyperbolicSineFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end

struct ArcHyperbolicTangentFunction{T} <: AbstractNonlinearScalarFunction
    expr::AbstractNonlinearScalarFunction
end
