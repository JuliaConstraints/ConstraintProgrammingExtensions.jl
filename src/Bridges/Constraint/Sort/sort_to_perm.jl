"""
Bridges `CP.Sort` to `CP.SortPermutation` by adding index variables.
"""
struct Sort2SortPermutationBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_int::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}}
    con_perm::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.SortPermutation}
end

function MOIBC.bridge_constraint(
    ::Type{Sort2SortPermutationBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Sort,
) where {T}
    return MOIBC.bridge_constraint(
        Sort2SortPermutationBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Sort2SortPermutationBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Sort,
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = s.dimension

    # Create new integer variables.
    vars, vars_int = MOI.add_constrained_variables(
        model, 
        [MOI.Integer() for _ in 1:dim]
    )

    # Create the SortPermutation constraint.
    con_perm = MOI.add_constraint(
        model, 
        MOIU.vectorize(
            MOI.ScalarAffineFunction{T}[
                f_scalars...,
                (one(T) .* MOI.SingleVariable.(vars))...
            ]
        ),
        CP.SortPermutation(dim)
    )

    return Sort2SortPermutationBridge(vars, vars_int, con_perm)
end

function MOI.supports_constraint(
    ::Type{Sort2SortPermutationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Sort},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Sort2SortPermutationBridge{T}}) where {T}
    return [(MOI.Integer,)]
end

function MOIB.added_constraint_types(::Type{Sort2SortPermutationBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.SortPermutation),
    ]
end

function MOI.get(b::Sort2SortPermutationBridge, ::MOI.NumberOfVariables)
    return length(b.vars)
end

function MOI.get(
    b::Sort2SortPermutationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.Integer,
    },
) where {T}
    return length(b.vars)
end

function MOI.get(
    ::Sort2SortPermutationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.SortPermutation,
    },
) where {T}
    return 1
end

function MOI.get(
    b::Sort2SortPermutationBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return copy(b.vars)
end

function MOI.get(
    b::Sort2SortPermutationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.Integer,
    },
) where {T}
    return copy(b.vars_int)
end

function MOI.get(
    b::Sort2SortPermutationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.SortPermutation,
    },
) where {T}
    return [b.con_perm]
end
