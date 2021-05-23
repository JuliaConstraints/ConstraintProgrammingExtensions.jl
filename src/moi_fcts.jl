abstract type AbstractNonlinearScalarFunction <: MOI.AbstractScalarFunction end

const NL_SV_FCT = Union{AbstractNonlinearScalarFunction, MOI.SingleVariable}

# -----------------------------------------------------------------------------
# - Affine expressions of nonlinear terms, inspired by MOI.ScalarAffineFunction
# - These generalise quadratic expressions too.
# -----------------------------------------------------------------------------

struct NonlinearScalarAffineTerm{T}
    coefficient::T
    expr::NL_SV_FCT
end

function NonlinearScalarAffineTerm(expr::NL_SV_FCT)
    return NonlinearScalarAffineTerm(1.0, expr)
end

struct NonlinearScalarAffineFunction{T} <: AbstractNonlinearScalarFunction
    terms::Vector{NonlinearScalarAffineTerm{T}}
    constant::T
end

function NonlinearScalarAffineFunction{T}(terms::Vector{NonlinearScalarAffineTerm{T}}) where {T}
    return NonlinearScalarAffineFunction(terms, one(T))
end

# -----------------------------------------------------------------------------
# - Geometric programming
# -----------------------------------------------------------------------------

# Aka monomial.
# Division: exponent -1.0.
# Square root: exponent 0.5.
struct NonlinearScalarFactor{T}
    exponent::T
    expr::NL_SV_FCT
end

function NonlinearScalarFactor(expr::NL_SV_FCT)
    return NonlinearScalarFactor(1.0, expr)
end

# Posynomial if the constant is > 0, signomial otherwise.
struct NonlinearScalarProductFunction{T} <: AbstractNonlinearScalarFunction
    factors::Vector{NonlinearScalarFactor{T}}
    constant::T
end

function NonlinearScalarProductFunction{T}(factors::Vector{NonlinearScalarFactor{T}}) where {T}
    return NonlinearScalarProductFunction(factors, one(T))
end

# -----------------------------------------------------------------------------
# - Usual nonlinear combinations of functions
# -----------------------------------------------------------------------------

struct AbsoluteValueFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ExponentialFunction{T} <: AbstractNonlinearScalarFunction
    exponent::T
    expr::NL_SV_FCT
end

function ExponentialFunction(expr::AbstractNonlinearScalarFunction)
    return ExponentialFunction{Float64}(ℯ, expr)
end

struct LogarithmFunction{T} <: AbstractNonlinearScalarFunction
    base::T
    expr::NL_SV_FCT
end

function LogarithmFunction(expr::AbstractNonlinearScalarFunction)
    return LogarithmFunction{Float64}(ℯ, expr)
end

# -----------------------------------------------------------------------------
# - Trigonometry
# -----------------------------------------------------------------------------

struct CosineFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct SineFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct TangentFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ArcCosineFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ArcSineFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ArcTangentFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct HyperbolicCosineFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct HyperbolicSineFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct HyperbolicTangentFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ArcHyperbolicCosineFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ArcHyperbolicSineFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ArcHyperbolicTangentFunction{T} <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

# -----------------------------------------------------------------------------
# - Nicer interface to some functions
# -----------------------------------------------------------------------------

function ProductFunction(a::NL_SV_FCT, b::NL_SV_FCT)
    factor_a = NonlinearScalarFactor(a)
    factor_b = NonlinearScalarFactor(b)
    return NonlinearScalarProductFunction([factor_a, factor_b])
end

function SquareRootFunction(expr::NL_SV_FCT)
    factor = NonlinearScalarFactor(1/2, expr)
    return NonlinearScalarProductFunction([factor])
end

function InverseFunction(expr::NL_SV_FCT)
    factor = NonlinearScalarFactor(-1, expr)
    return NonlinearScalarProductFunction([factor])
end

# -----------------------------------------------------------------------------
# - Relations with linear/quadratic types of MOI
# -----------------------------------------------------------------------------

function NonlinearScalarAffineTerm(term::MOI.ScalarAffineTerm)
    return NonlinearScalarAffineTerm(term.coefficient, term.variable)
end

function NonlinearScalarAffineFunction(fct::MOI.ScalarAffineFunction)
    return NonlinearScalarAffineFunction(NonlinearScalarAffineTerm.(fct.terms), fct.constant)
end

function NonlinearScalarAffineTerm(term::MOI.ScalarQuadraticTerm)
    prod = ProductFunction(term.variable_1, term.variable_2)
    return NonlinearScalarAffineTerm(term.coefficient, prod)
end

function NonlinearScalarAffineFunction(fct::MOI.ScalarQuadraticFunction)
    terms = NonlinearScalarAffineTerm.([fct.affine_terms..., fct.quadratic_terms...])
    return NonlinearScalarAffineFunction(terms, fct.constant)
end
