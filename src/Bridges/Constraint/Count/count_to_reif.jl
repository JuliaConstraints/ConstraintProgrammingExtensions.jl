"""
Bridges `CP.Count` to reification.
"""
struct Count2ReificationBridge{T, S <: MOI.AbstractScalarSet} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reification{S}}}
    con_sum::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Count2ReificationBridge{T, S}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Count{S},
) where {T, S <: MOI.AbstractScalarSet}
    return MOIBC.bridge_constraint(
        Count2ReificationBridge{T, S},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Count2ReificationBridge{T, S}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Count{S},
) where {T, S <: MOI.AbstractScalarSet}
    vars, vars_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.dimension])

    f_scalars = MOIU.scalarize(f)
    cons = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reification{S}}[
        MOI.add_constraint(
            model,
            MOIU.vectorize(
                MOI.ScalarAffineFunction{T}[
                    one(T) * MOI.SingleVariable(vars[i]), 
                    f_scalars[1 + i],
                ]
            ),
            CP.Reification(s.set)
        )
        for i in 1:s.dimension
    ]

    con_sum = MOI.add_constraint(
        model, 
        sum(one(T) .* MOI.SingleVariable.(vars)) - f_scalars[1],
        MOI.EqualTo(zero(T))
    )

    return Count2ReificationBridge(vars, vars_bin, cons, con_sum)
end

function MOI.supports_constraint(
    ::Type{Count2ReificationBridge{T, S}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Count{S}},
) where {T, S <: MOI.AbstractScalarSet}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Count2ReificationBridge{T, S}}) where {T, S <: MOI.AbstractScalarSet}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Count2ReificationBridge{T, S}}) where {T, S <: MOI.AbstractScalarSet}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.VectorAffineFunction{T}, CP.Reification{S}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{Count2ReificationBridge{T, S}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Count{S}},
) where {T, S <: MOI.AbstractScalarSet}
    return Count2ReificationBridge{T, S}
end

function MOI.get(b::Count2ReificationBridge{T, S}, ::MOI.NumberOfVariables) where {T, S <: MOI.AbstractScalarSet}
    return length(b.vars)
end

function MOI.get(
    b::Count2ReificationBridge{T, S},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T, S <: MOI.AbstractScalarSet}
    return length(b.vars_bin)
end

function MOI.get(
    b::Count2ReificationBridge{T, S},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Reification{S},
    },
) where {T, S <: MOI.AbstractScalarSet}
    return length(b.cons)
end

function MOI.get(
    ::Count2ReificationBridge{T, S},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T, S <: MOI.AbstractScalarSet}
    return 1
end

function MOI.get(
    b::Count2ReificationBridge{T, S},
    ::MOI.ListOfVariableIndices,
) where {T, S <: MOI.AbstractScalarSet}
    return copy(b.vars)
end

function MOI.get(
    b::Count2ReificationBridge{T, S},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T, S <: MOI.AbstractScalarSet}
    return copy(b.vars_bin)
end

function MOI.get(
    b::Count2ReificationBridge{T, S},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Reification{S},
    },
) where {T, S <: MOI.AbstractScalarSet}
    return copy(b.cons)
end

function MOI.get(
    b::Count2ReificationBridge{T, S},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T, S <: MOI.AbstractScalarSet}
    return [b.con_sum]
end
