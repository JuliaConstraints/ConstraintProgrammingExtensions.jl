"""
Bridges `CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T}`
to `CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T`.
"""
struct GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T} <: MOIBC.AbstractBridge
    cons_domain::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Domain{T}}}
    con_gc::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.GlobalCardinality{T}}
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T},
) where {T}
    return MOIBC.bridge_constraint(
        GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T},
) where {T}
    f_scalars = MOIU.scalarize(f)

    cons_domain = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Domain{T}}[
        MOI.add_constraint(
            model,
            f_scalars[i],
            CP.Domain(Set(s.values)),
            # Create one set object per constraint to avoid sharing any state.
        ) 
        for i in 1:s.dimension
    ]

    con_gc = MOI.add_constraint(
        model,
        f,
        CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}(s.dimension, copy(s.values)),
        # Copy the values for each constraint to avoid sharing any state.
    )

    return GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge(cons_domain, con_gc)
end

function MOI.supports_constraint(
    ::Type{GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, CP.Domain{T}),
        (MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}),
    ]
end

function MOI.get(
    b::GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.Domain{T},
    },
) where {T}
    return length(b.cons_domain)
end

function MOI.get(
    ::GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.Domain{T},
    },
) where {T}
    return copy(b.cons_domain)
end

function MOI.get(
    b::GlobalCardinalityFixedClosed2GlobalCardinalityFixedOpenBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T},
    },
) where {T}
    return [b.con_gc]
end
