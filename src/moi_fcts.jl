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

function copy(t::NonlinearScalarAffineTerm{T}) where {T}
    return NonlinearScalarAffineTerm(copy(t.coefficient), copy(t.expr))
end


mutable struct NonlinearScalarAffineFunction{T} <: AbstractNonlinearScalarFunction
    terms::Vector{NonlinearScalarAffineTerm{T}}
    constant::T
end

function NonlinearScalarAffineFunction(terms::Vector{NonlinearScalarAffineTerm{T}}) where {T}
    return NonlinearScalarAffineFunction(terms, one(T))
end

function copy(f::NonlinearScalarAffineFunction{T}) where {T}
    return NonlinearScalarAffineFunction(copy.(f.terms), copy(f.constant))
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

function copy(f::NonlinearScalarFactor{T}) where {T}
    return NonlinearScalarFactor(copy(f.exponent), copy(f.expr))
end


# Posynomial if the constant is > 0, signomial otherwise.
mutable struct NonlinearScalarProductFunction{T} <: AbstractNonlinearScalarFunction
    factors::Vector{NonlinearScalarFactor{T}}
    constant::T
end

function NonlinearScalarProductFunction(factors::Vector{NonlinearScalarFactor{T}}) where {T}
    return NonlinearScalarProductFunction(factors, one(T))
end

function copy(f::NonlinearScalarProductFunction{T}) where {T}
    return NonlinearScalarProductFunction(copy.(f.factors), copy(f.constant))
end

# -----------------------------------------------------------------------------
# - Usual nonlinear combinations of functions
# -----------------------------------------------------------------------------

struct AbsoluteValueFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

function copy(f::AbsoluteValueFunction)
    return AbsoluteValueFunction(copy(f.expr))
end


struct ExponentialFunction{T} <: AbstractNonlinearScalarFunction
    exponent::T
    expr::NL_SV_FCT
end

function ExponentialFunction(expr::AbstractNonlinearScalarFunction)
    return ExponentialFunction{Float64}(ℯ, expr)
end

function copy(f::ExponentialFunction)
    return ExponentialFunction(copy(f.exponent), copy(f.expr))
end


struct LogarithmFunction{T} <: AbstractNonlinearScalarFunction
    base::T
    expr::NL_SV_FCT
end

function LogarithmFunction(expr::AbstractNonlinearScalarFunction)
    return LogarithmFunction{Float64}(ℯ, expr)
end

function copy(f::LogarithmFunction)
    return LogarithmFunction(copy(f.base), copy(f.expr))
end

# -----------------------------------------------------------------------------
# - Trigonometry
# -----------------------------------------------------------------------------

struct CosineFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct SineFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct TangentFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ArcCosineFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ArcSineFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct ArcTangentFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct HyperbolicCosineFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct HyperbolicSineFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct HyperbolicTangentFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct HyperbolicArcCosineFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct HyperbolicArcSineFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

struct HyperbolicArcTangentFunction <: AbstractNonlinearScalarFunction
    expr::NL_SV_FCT
end

function copy(f::F) where {F <: Union{
    CosineFunction, SineFunction, TangentFunction, 
    ArcCosineFunction, ArcSineFunction, ArcTangentFunction, 
    HyperbolicCosineFunction, HyperbolicSineFunction, HyperbolicTangentFunction, 
    HyperbolicArcCosineFunction, HyperbolicArcSineFunction, HyperbolicArcTangentFunction,
}}
    return F(copy(f.expr))
end

# -----------------------------------------------------------------------------
# - Nicer interface to some functions
# -----------------------------------------------------------------------------

function ProductFunction(fs::NL_SV_FCT...)
    factors = [NonlinearScalarFactor(f) for f in fs]
    return NonlinearScalarProductFunction(factors)
end

function SquareRootFunction(expr::NL_SV_FCT)
    factor = NonlinearScalarFactor(0.5, expr)
    return NonlinearScalarProductFunction([factor])
end

function InverseFunction(expr::NL_SV_FCT)
    factor = NonlinearScalarFactor(-1.0, expr)
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
