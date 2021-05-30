# -----------------------------------------------------------------------------
# - Function version of some sets that imply returning a value
# -----------------------------------------------------------------------------

struct CountFunction{F <: NL_SV_FCT, G <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
    target::G
end

struct CountCompareFunction{F <: NL_SV_FCT, G <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array_source::Vector{<:F}
    array_destination::Vector{<:G}
end

struct CountDistinctFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
end

struct ElementFunction{F <: NL_SV_FCT, G <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
    index::Vector{<:G}
end

struct MinimumDistanceFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
end

struct MaximumDistanceFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
end

struct MinimumFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
end

struct MaximumFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
end

struct ArgumentMinimumFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
end

struct ArgumentMaximumFunction{F <: NL_SV_FCT} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
end
