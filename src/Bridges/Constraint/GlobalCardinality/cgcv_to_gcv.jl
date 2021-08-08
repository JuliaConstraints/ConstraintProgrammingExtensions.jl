"""
Bridges 
`GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T}`
to `GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}`.
"""
struct GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T} <: MOIBC.AbstractBridge
    cons_domain::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Membership}}
    con_gcv::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}}
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T},
) where {T}
    return MOIBC.bridge_constraint(
        GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T},
) where {T}
    f_scalars = MOIU.scalarize(f)
    f_sought = f_scalars[(s.dimension + s.n_values + 1):(s.dimension + 2 * s.n_values)]

    cons_domain = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Membership}[
        MOI.add_constraint(
            model,
            MOIU.vectorize(
                [
                    f_scalars[i],
                    f_sought...
                ]
            ),
            CP.Membership(s.n_values),
        ) 
        for i in 1:s.dimension
    ]

    con_gcv = MOI.add_constraint(
        model,
        f,
        CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}(s.dimension, s.n_values),
    )

    return GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge(cons_domain, con_gcv)
end

function MOI.supports_constraint(
    ::Type{GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.CLOSED_COUNTED_VALUES, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Membership),
        (MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}),
    ]
end

function MOI.get(
    b::GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Membership,
    },
) where {T}
    return length(b.cons_domain)
end

function MOI.get(
    ::GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Membership,
    },
) where {T}
    return copy(b.cons_domain)
end

function MOI.get(
    b::GlobalCardinalityVariableClosed2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T},
    },
) where {T}
    return [b.con_gcv]
end
