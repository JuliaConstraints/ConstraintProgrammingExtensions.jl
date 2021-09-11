"""
Bridges `CP.DoublyLexicographicallyGreaterThan` to `CP.LexicographicallyGreaterThan`.
"""
struct DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T} <: MOIBC.AbstractBridge
    con::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.LexicographicallyGreaterThan} # Columns are lexicographically sorted.
    con_transposed::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.LexicographicallyGreaterThan} # Rows are lexicographically sorted.
end

function MOIBC.bridge_constraint(
    ::Type{DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.DoublyLexicographicallyGreaterThan,
) where {T}
    return MOIBC.bridge_constraint(
        DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.DoublyLexicographicallyGreaterThan,
) where {T}
    # Constraint on columns.
    con = MOI.add_constraint(
        model,
        f,
        CP.LexicographicallyGreaterThan(s.row_dim, s.column_dim)
    )

    # Constraint on rows.
    f_scalars = MOIU.scalarize(f)
    f_matrix = reshape(f_scalars, s.row_dim, s.column_dim)
    f_transposed = MOIU.vectorize(vec(f_matrix)) # vec() does the transposition.

    con_transposed = MOI.add_constraint(
        model, 
        f_transposed,
        CP.LexicographicallyGreaterThan(s.column_dim, s.row_dim)
    )

    return DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge(con, con_transposed)
end

function MOI.supports_constraint(
    ::Type{DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.DoublyLexicographicallyGreaterThan},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T}}) where {T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.LexicographicallyGreaterThan),
    ]
end

function MOI.get(
    ::DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.LexicographicallyGreaterThan,
    },
) where {T}
    return 2
end

function MOI.get(
    b::DoublyLexicographicallyGreaterThan2LexicographicallyGreaterThanBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.LexicographicallyGreaterThan,
    },
) where {T}
    return [b.con, b.con_transposed]
end
