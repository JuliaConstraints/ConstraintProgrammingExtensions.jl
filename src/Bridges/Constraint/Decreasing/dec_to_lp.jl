"""
Bridges `CP.Decreasing` to linear constraints.
"""
struct Decreasing2LPBridge{T} <: MOIBC.AbstractBridge
    cons::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{Decreasing2LPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Decreasing,
) where {T}
    return MOIBC.bridge_constraint(
        Decreasing2LPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Decreasing2LPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Decreasing,
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = MOI.output_dimension(f)

    cons = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}[
        MOI.add_constraint(
            model,
            f_scalars[i] - f_scalars[i + 1],
            MOI.GreaterThan(zero(T))
        )
        for i in 1:(dim - 1)
    ]

    return Decreasing2LPBridge(cons)
end

function MOI.supports_constraint(
    ::Type{Decreasing2LPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Decreasing},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Decreasing2LPBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{Decreasing2LPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{Decreasing2LPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Decreasing},
) where {T}
    return Decreasing2LPBridge{T}
end

function MOI.get(::Decreasing2LPBridge, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    b::Decreasing2LPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::Decreasing2LPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return b.cons
end
