"""
Bridges `CP.GlobalCardinality` to `CP.Count`.
"""
struct GlobalCardinality2CountBridge{T} <: MOIBC.AbstractBridge
    cons_count::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}}}
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinality2CountBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.GlobalCardinality{T},
) where {T}
    return MOIBC.bridge_constraint(
        GlobalCardinality2CountBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinality2CountBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.GlobalCardinality{T},
) where {T}
    f_scalars = MOIU.scalarize(f)
    f_array = f_scalars[1:s.dimension]

    cons_count = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}}[
        MOI.add_constraint(
            model,
            MOIU.vectorize(
                MOI.ScalarAffineFunction{T}[
                    f_scalars[s.dimension + i],
                    f_array...,
                ]
            ),
            CP.Count(s.dimension, MOI.EqualTo(s.values[i]))
        )
        for i in 1:length(s.values)
    ]

    return GlobalCardinality2CountBridge(cons_count)
end

function MOI.supports_constraint(
    ::Type{GlobalCardinality2CountBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.GlobalCardinality{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{GlobalCardinality2CountBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{GlobalCardinality2CountBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{GlobalCardinality2CountBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.GlobalCardinality{T}},
) where {T}
    return GlobalCardinality2CountBridge{T}
end

function MOI.get(::GlobalCardinality2CountBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 0
end

function MOI.get(
    b::GlobalCardinality2CountBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}},
    },
) where {T}
    return length(b.cons_count)
end

function MOI.get(
    b::GlobalCardinality2CountBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}},
    },
) where {T}
    return copy(b.cons_count)
end
