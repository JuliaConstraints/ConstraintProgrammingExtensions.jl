"""
Bridges `CP.SortPermutation` to `CP.AllDifferent` and 
`CP.ElementVariableArray`.
"""
struct SortPermutation2AllDifferentBridge{T} <: MOIBC.AbstractBridge
    con_alldiff::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.AllDifferent}
    cons_value::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.ElementVariableArray}}
    cons_sort::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{SortPermutation2AllDifferentBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.SortPermutation,
) where {T}
    return MOIBC.bridge_constraint(
        SortPermutation2AllDifferentBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{SortPermutation2AllDifferentBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.SortPermutation,
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = s.dimension

    sorted_array = f_scalars[1:dim]
    array = f_scalars[(dim + 1):(2 * dim)]
    indices = f_scalars[(2 * dim + 1):(3 * dim)]

    # The values must be sorted.
    # TODO: use CP.Increasing instead? 
    cons_sort = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}[
        MOI.add_constraint(
            model, 
            sorted_array[i] - sorted_array[i + 1],
            MOI.GreaterThan(zero(T))
        )
        for i in 1:(dim - 1)
    ]

    # The indices must take different values, one per index in the array.
    con_alldiff = MOI.add_constraint(
        model, 
        MOIU.vectorize(indices),
        CP.AllDifferent(dim)
    )

    # Relate the three sets of variables by indexing.
    cons_value = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.ElementVariableArray}[
        MOI.add_constraint(
            model, 
            MOIU.vectorize(
                [
                    sorted_array[i],
                    indices[i],
                    array...
                ]
            ),
            CP.ElementVariableArray(dim)
        )
        for i in 1:dim
    ]

    return SortPermutation2AllDifferentBridge(con_alldiff, cons_value, cons_sort)
end

function MOI.supports_constraint(
    ::Type{SortPermutation2AllDifferentBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.SortPermutation},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{SortPermutation2AllDifferentBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{SortPermutation2AllDifferentBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.AllDifferent),
        (MOI.ScalarAffineFunction{T}, CP.ElementVariableArray),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOI.get(
    ::SortPermutation2AllDifferentBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.AllDifferent,
    },
) where {T}
    return 1
end

function MOI.get(
    b::SortPermutation2AllDifferentBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.ElementVariableArray,
    },
) where {T}
    return length(b.cons_value)
end

function MOI.get(
    b::SortPermutation2AllDifferentBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.cons_sort)
end

function MOI.get(
    b::SortPermutation2AllDifferentBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.AllDifferent,
    },
) where {T}
    return [b.con_alldiff]
end

function MOI.get(
    b::SortPermutation2AllDifferentBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.ElementVariableArray,
    },
) where {T}
    return copy(b.cons_value)
end

function MOI.get(
    b::SortPermutation2AllDifferentBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return copy(b.cons_sort)
end
