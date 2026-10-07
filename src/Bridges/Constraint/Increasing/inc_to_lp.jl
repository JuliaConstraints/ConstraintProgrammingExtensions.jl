"""
Bridges `CP.Increasing` to linear constraints.
"""
struct Increasing2LPBridge{T} <: MOIBC.AbstractBridge
    cons::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{Increasing2LPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Increasing,
) where {T}
    return MOIBC.bridge_constraint(
        Increasing2LPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Increasing2LPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Increasing,
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = MOI.output_dimension(f)

    cons = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}[
        MOI.add_constraint(
            model,
            f_scalars[i] - f_scalars[i + 1],
            MOI.LessThan(zero(T))
        )
        for i in 1:(dim - 1)
    ]

    return Increasing2LPBridge(cons)
end

function MOI.supports_constraint(
    ::Type{Increasing2LPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Increasing},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Increasing2LPBridge{T}}) where {T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{Increasing2LPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOI.get(
    b::Increasing2LPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::Increasing2LPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return copy(b.cons)
end
