"""
Bridges `CP.DoublyLexicographicallyLessThan` to `CP.LexicographicallyLessThan`.
"""
struct DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T} <: MOIBC.AbstractBridge
    con::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.LexicographicallyLessThan} # Columns are lexicographically sorted.
    con_transposed::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.LexicographicallyLessThan} # Rows are lexicographically sorted.
end

function MOIBC.bridge_constraint(
    ::Type{DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.DoublyLexicographicallyLessThan,
) where {T}
    return MOIBC.bridge_constraint(
        DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.DoublyLexicographicallyLessThan,
) where {T}
    # Constraint on columns.
    con = MOI.add_constraint(
        model,
        f,
        CP.LexicographicallyLessThan(s.row_dim, s.column_dim)
    )

    # Constraint on rows.
    f_scalars = MOIU.scalarize(f)
    f_matrix = reshape(f_scalars, s.row_dim, s.column_dim)
    f_transposed = MOIU.vectorize(vec(f_matrix)) # vec() does the transposition.

    con_transposed = MOI.add_constraint(
        model, 
        f_transposed,
        CP.LexicographicallyLessThan(s.column_dim, s.row_dim)
    )

    return DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge(con, con_transposed)
end

function MOI.supports_constraint(
    ::Type{DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.DoublyLexicographicallyLessThan},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.LexicographicallyLessThan),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.DoublyLexicographicallyLessThan},
) where {T}
    return DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}
end

function MOI.get(::DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 0
end

function MOI.get(
    ::DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.LexicographicallyLessThan,
    },
) where {T}
    return 2
end

function MOI.get(
    b::DoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.LexicographicallyLessThan,
    },
) where {T}
    return [b.con, b.con_transposed]
end
