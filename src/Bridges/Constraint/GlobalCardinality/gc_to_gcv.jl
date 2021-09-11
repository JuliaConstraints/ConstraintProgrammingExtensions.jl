"""
Bridges `CP.GlobalCardinality` to `CP.GlobalCardinalityVariable`.
"""
struct GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_int::Vector{MOI.ConstraintIndex{MOI.VariableIndex, MOI.Integer}}
    cons_eq::Vector{MOI.ConstraintIndex{MOI.VariableIndex, MOI.EqualTo{T}}}
    con_gcv::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}}
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T},
) where {T}
    return MOIBC.bridge_constraint(
        GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T},
) where {T}
    # Create the variables that contain the values that are counted.
    if T <: Integer
        vars, vars_int = MOI.add_constrained_variables(
            model, 
            [MOI.Integer() for _ in 1:length(s.values)]
        )
    else
        vars = MOI.add_variables(model, length(s.values))
        vars_int = MOI.ConstraintIndex{MOI.VariableIndex, MOI.Integer}[]
    end

    # Constrain these variables to take the sought (fixed) values.
    cons_eq = [
        MOI.add_constraint(
            model,
            vars[i],
            MOI.EqualTo(s.values[i])
        ) 
        for i in 1:length(s.values)
    ]

    # Create the new global-cardinality constraint.
    f_scalars = MOIU.scalarize(f)
    con_gcv = MOI.add_constraint(
        model,
        MOIU.vectorize(
            [
                f_scalars...,
                (one(T) .* MOI.VariableIndex.(vars))...
            ]
        ),
        CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}(s.dimension, length(s.values))
    )

    return GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge(vars, vars_int, cons_eq, con_gcv)
end

function MOI.supports_constraint(
    ::Type{GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.GlobalCardinality{CP.FIXED_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T}}) where {T <: Integer}
    return [(MOI.Integer,)]
end

function MOIB.added_constrained_variable_types(::Type{GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T}}) where {T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T}}) where {T}
    return [
        (MOI.VariableIndex, MOI.EqualTo{T}),
        (MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T}),
    ]
end

function MOI.get(b::GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T}, ::MOI.NumberOfVariables) where {T}
    return length(b.vars)
end

function MOI.get(
    b::GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VariableIndex, MOI.Integer,
    },
) where {T}
    return length(b.vars_int)
end

function MOI.get(
    b::GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VariableIndex, MOI.EqualTo{T},
    },
) where {T}
    return length(b.cons_eq)
end

function MOI.get(
    ::GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return copy(b.vars)
end

function MOI.get(
    b::GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VariableIndex, MOI.Integer,
    },
) where {T}
    return copy(b.vars_int)
end

function MOI.get(
    b::GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VariableIndex, MOI.EqualTo{T},
    },
) where {T}
    return copy(b.cons_eq)
end

function MOI.get(
    b::GlobalCardinalityFixedOpen2GlobalCardinalityVariableOpenBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinality{CP.VARIABLE_COUNTED_VALUES, CP.OPEN_COUNTED_VALUES, T},
    },
) where {T}
    return [b.con_gcv]
end
