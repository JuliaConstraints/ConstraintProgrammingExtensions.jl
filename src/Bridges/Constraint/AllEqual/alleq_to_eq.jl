"""
Bridges `CP.AllEqual` to a series of `CP.EqualTo`.
"""
struct AllEqual2EqualToBridge{T} <: MOIBC.AbstractBridge
    # For an AllEqual set of dimension `d`, vector of size `d-1`: first 
    # variable equal to the `i+1`th.
    cons::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{AllEqual2EqualToBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.AllEqual,
) where {T}
    return MOIBC.bridge_constraint(
        AllEqual2EqualToBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{AllEqual2EqualToBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.AllEqual,
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = MOI.output_dimension(f)

    cons = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
        MOI.add_constraint(
            model,
            f_scalars[1] - f_scalars[i],
            MOI.EqualTo(zero(T))
        )
        for i in 2:dim
    ]

    return AllEqual2EqualToBridge(cons)
end

function MOI.supports_constraint(
    ::Type{AllEqual2EqualToBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.AllEqual},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{AllEqual2EqualToBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{AllEqual2EqualToBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{AllEqual2EqualToBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.AllEqual},
) where {T}
    return AllEqual2EqualToBridge{T}
end

function MOI.get(::AllEqual2EqualToBridge, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    b::AllEqual2EqualToBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::AllEqual2EqualToBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return collect(values(b.cons))
end
