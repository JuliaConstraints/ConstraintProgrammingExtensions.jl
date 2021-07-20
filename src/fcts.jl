# -----------------------------------------------------------------------------
# - Function version of some sets that imply returning a value
# -----------------------------------------------------------------------------

struct CountFunction{F <: NL_SV_FCT, S <: MOI.AbstractScalarSet} <: AbstractNonlinearScalarFunction
    array::Vector{<:F}
    comparison::S
end

function CountFunction(array::Vector{<:F}, value::T)
    return CountFunction(array, MOI.EqualTo{T}(value))
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

struct BinPackingLoadFunction{F <: NL_SV_FCT, T <: Real} <: AbstractNonlinearVectorFunction
    bin_assignment::Vector{<:F}
    weights::Vector{T}
end
