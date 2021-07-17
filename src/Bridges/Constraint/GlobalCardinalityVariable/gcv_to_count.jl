"""
Bridges `CP.GlobalCardinalityVariable` to `CP.Count`.
"""
struct GlobalCardinalityVariable2CountBridge{T} <: MOIBC.AbstractBridge
    cons_count::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}}}
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinalityVariable2CountBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.GlobalCardinalityVariable,
) where {T}
    return MOIBC.bridge_constraint(
        GlobalCardinalityVariable2CountBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinalityVariable2CountBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.GlobalCardinalityVariable,
) where {T}
    f_scalars = MOIU.scalarize(f)
    f_array = f_scalars[1:s.dimension]
    f_counts = f_scalars[(s.dimension + 1) : (s.dimension + s.n_values)]
    f_values = f_scalars[(s.dimension + s.n_values + 1) : (s.dimension + 2 * s.n_values)]

    cons_count = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}}[
        MOI.add_constraint(
            model,
            MOIU.vectorize(
                MOI.ScalarAffineFunction{T}[
                    f_counts[i],
                    (f_array .- f_values[i])...,
                ]
            ),
            CP.Count(s.dimension, MOI.EqualTo(zero(T)))
        )
        for i in 1:s.n_values
    ]

    return GlobalCardinalityVariable2CountBridge(cons_count)
end

function MOI.supports_constraint(
    ::Type{GlobalCardinalityVariable2CountBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.GlobalCardinalityVariable},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{GlobalCardinalityVariable2CountBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{GlobalCardinalityVariable2CountBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{GlobalCardinalityVariable2CountBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.GlobalCardinalityVariable},
) where {T}
    return GlobalCardinalityVariable2CountBridge{T}
end

function MOI.get(::GlobalCardinalityVariable2CountBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 0
end

function MOI.get(
    b::GlobalCardinalityVariable2CountBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}},
    },
) where {T}
    return length(b.cons_count)
end

function MOI.get(
    b::GlobalCardinalityVariable2CountBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}},
    },
) where {T}
    return copy(b.cons_count)
end
