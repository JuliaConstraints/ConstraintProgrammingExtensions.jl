"""
Bridges `CP.GlobalCardinality` to `CP.GlobalCardinalityVariable`.
"""
struct GlobalCardinality2GlobalCardinalityVariableBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_int::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}}
    cons_eq::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo{T}}}
    con_gcv::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable}
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinality2GlobalCardinalityVariableBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.GlobalCardinality{FIXED_COUNTED_VALUES, OPEN_COUNTED_VALUES, T},
) where {T}
    return MOIBC.bridge_constraint(
        GlobalCardinality2GlobalCardinalityVariableBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{GlobalCardinality2GlobalCardinalityVariableBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.GlobalCardinality{FIXED_COUNTED_VALUES, OPEN_COUNTED_VALUES, T},
) where {T}
    # Create the variables that contain the values that are counted.
    if T <: Integer
        vars, vars_int = MOI.add_constrained_variables(
            model, 
            [MOI.Integer() for _ in 1:length(s.values)]
        )
    else
        vars = MOI.add_variables(model, length(s.values))
        vars_int = MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}[]
    end

    # Constrain these variables to take the sought (fixed) values.
    cons_eq = [
        MOI.add_constraint(
            model,
            MOI.SingleVariable(vars[i]),
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
                (one(T) .* MOI.SingleVariable.(vars))...
            ]
        ),
        CP.GlobalCardinality{VARIABLE_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}(s.dimension, length(s.values))
    )

    return GlobalCardinality2GlobalCardinalityVariableBridge(vars, vars_int, cons_eq, con_gcv)
end

function MOI.supports_constraint(
    ::Type{GlobalCardinality2GlobalCardinalityVariableBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.GlobalCardinality{FIXED_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{GlobalCardinality2GlobalCardinalityVariableBridge{T}}) where {T <: Integer}
    return [(MOI.Integer,)]
end

function MOIB.added_constrained_variable_types(::Type{GlobalCardinality2GlobalCardinalityVariableBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{GlobalCardinality2GlobalCardinalityVariableBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.EqualTo{T}),
        (MOI.VectorAffineFunction{T}, CP.GlobalCardinality{VARIABLE_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}),
    ]
end

function MOI.get(b::GlobalCardinality2GlobalCardinalityVariableBridge{T}, ::MOI.NumberOfVariables) where {T}
    return length(b.vars)
end

function MOI.get(
    b::GlobalCardinality2GlobalCardinalityVariableBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.Integer,
    },
) where {T}
    return length(b.vars_int)
end

function MOI.get(
    b::GlobalCardinality2GlobalCardinalityVariableBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.EqualTo{T},
    },
) where {T}
    return length(b.cons_eq)
end

function MOI.get(
    ::GlobalCardinality2GlobalCardinalityVariableBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable,
    },
) where {T}
    return 1
end

function MOI.get(
    b::GlobalCardinality2GlobalCardinalityVariableBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return copy(b.vars)
end

function MOI.get(
    b::GlobalCardinality2GlobalCardinalityVariableBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.Integer,
    },
) where {T}
    return copy(b.vars_int)
end

function MOI.get(
    b::GlobalCardinality2GlobalCardinalityVariableBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.EqualTo{T},
    },
) where {T}
    return copy(b.cons_eq)
end

function MOI.get(
    b::GlobalCardinality2GlobalCardinalityVariableBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable,
    },
) where {T}
    return [b.con_gcv]
end
