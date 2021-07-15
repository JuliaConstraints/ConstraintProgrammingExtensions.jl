"""
Bridges `CP.SlidingSum` to linear constraints.
"""
struct SlidingSum2LPBridge{T} <: MOIBC.AbstractBridge
    cons::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.Interval{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{SlidingSum2LPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.SlidingSum{T},
) where {T}
    return MOIBC.bridge_constraint(
        SlidingSum2LPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{SlidingSum2LPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.SlidingSum{T},
) where {T}
    f_scalars = MOIU.scalarize(f)
    cons = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.Interval{T}}[
        MOI.add_constraint(
            model,
            sum(f_scalars[i:(i + s.length - 1)]),
            MOI.Interval(s.low, s.high)
        )
        for i in 1:(s.dimension - s.length)
    ]

    return SlidingSum2LPBridge(cons)
end

function MOI.supports_constraint(
    ::Type{SlidingSum2LPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.SlidingSum{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{SlidingSum2LPBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{SlidingSum2LPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.Interval{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{SlidingSum2LPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.SlidingSum{T}},
) where {T}
    return SlidingSum2LPBridge{T}
end

function MOI.get(::SlidingSum2LPBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 0
end

function MOI.get(
    b::SlidingSum2LPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.Interval{T},
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::SlidingSum2LPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.Interval{T},
    },
) where {T}
    return b.cons
end
