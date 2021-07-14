"""
Bridges `CP.ClosedGlobalCardinality` to `CP.GlobalCardinality`.
"""
struct ClosedGlobalCardinality2GlobalCardinalityBridge{T} <: MOIBC.AbstractBridge
    cons_domain::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Domain{T}}}
    con_gc::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.GlobalCardinality{T}}
end

function MOIBC.bridge_constraint(
    ::Type{ClosedGlobalCardinality2GlobalCardinalityBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.ClosedGlobalCardinality{T},
) where {T}
    return MOIBC.bridge_constraint(
        ClosedGlobalCardinality2GlobalCardinalityBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ClosedGlobalCardinality2GlobalCardinalityBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.ClosedGlobalCardinality{T},
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
        CP.GlobalCardinality(s.dimension, copy(s.values)),
        # Copy the values for each constraint to avoid sharing any state.
    )

    return ClosedGlobalCardinality2GlobalCardinalityBridge(cons_domain, con_gc)
end

function MOI.supports_constraint(
    ::Type{ClosedGlobalCardinality2GlobalCardinalityBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.ClosedGlobalCardinality{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ClosedGlobalCardinality2GlobalCardinalityBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{ClosedGlobalCardinality2GlobalCardinalityBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, CP.Domain{T}),
        (MOI.VectorAffineFunction{T}, CP.GlobalCardinality{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{ClosedGlobalCardinality2GlobalCardinalityBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.ClosedGlobalCardinality{T}},
) where {T}
    return ClosedGlobalCardinality2GlobalCardinalityBridge{T}
end

function MOI.get(::ClosedGlobalCardinality2GlobalCardinalityBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 0
end

function MOI.get(
    b::ClosedGlobalCardinality2GlobalCardinalityBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.Domain{T},
    },
) where {T}
    return length(b.cons_domain)
end

function MOI.get(
    ::ClosedGlobalCardinality2GlobalCardinalityBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinality{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::ClosedGlobalCardinality2GlobalCardinalityBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.Domain{T},
    },
) where {T}
    return b.cons_domain
end

function MOI.get(
    b::ClosedGlobalCardinality2GlobalCardinalityBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinality{T},
    },
) where {T}
    return [b.con_gc]
end
