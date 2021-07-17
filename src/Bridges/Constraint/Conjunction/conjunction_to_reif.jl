"""
Bridges `CP.Conjunction` to reification.
"""
struct Conjunction2ReificationBridge{T} <: MOIBC.AbstractBridge
    var::MOI.VariableIndex
    var_bin::MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}
    cons_reif::Vector{MOI.ConstraintIndex}
    # Ideally, Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reification{<: MOI.AbstractSet}}}, 
    # but Julia has no notion of type erasure.
    con_conjunction::MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Conjunction2ReificationBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Conjunction{S},
) where {T, S}
    return MOIBC.bridge_constraint(
        Conjunction2ReificationBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Conjunction2ReificationBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Conjunction{S},
) where {T, S}
    var, var_bin = MOI.add_constrained_variable(model, MOI.ZeroOne())

    f_scalars = MOIU.scalarize(f)
    cons_reif = Vector{MOI.ConstraintIndex}(undef, length(s.constraints))
    cur_dim = 1
    for i in 1:length(s.constraints)
        cons_reif[i] = MOI.add_constraint(
            model,
            MOIU.vectorize(
                [
                    one(T) * MOI.SingleVariable(var),
                    f_scalars[cur_dim : (cur_dim + MOI.dimension(s.constraints[i]) - 1)]...,
                ]
            ),
            CP.Reification(s.constraints[i])
        )
        cur_dim += MOI.dimension(s.constraints[i])
    end

    con_conjunction = MOI.add_constraint(
        model, 
        MOI.SingleVariable(var),
        MOI.EqualTo(one(T))
    )

    return Conjunction2ReificationBridge(var, var_bin, cons_reif, con_conjunction)
end

function MOI.supports_constraint(
    ::Type{Conjunction2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Conjunction{S}},
) where {T, S}
    return true
    # Ideally, ensure that the underlying solver supports all the needed 
    # reified constraints:
    # return all(MOI.supports_constraint(model, type, CP.Reification{C}) for C in S.parameters)
end

function MOIB.added_constrained_variable_types(::Type{Conjunction2ReificationBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Conjunction2ReificationBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.VectorAffineFunction{T}, CP.Reification), # TODO: how to be more precise?
        (MOI.SingleVariable, MOI.EqualTo{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{Conjunction2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Conjunction{S}},
) where {T, S}
    return Conjunction2ReificationBridge{T}
end

function MOI.get(::Conjunction2ReificationBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 1
end

function MOI.get(
    ::Conjunction2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return 1
end

function MOI.get(
    b::Conjunction2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Reification,
    },
) where {T}
    return length(b.cons_reif)
end

function MOI.get(
    ::Conjunction2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.EqualTo{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::Conjunction2ReificationBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return [b.var]
end

function MOI.get(
    b::Conjunction2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return [b.var_bin]
end

function MOI.get(
    b::Conjunction2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Reification,
    },
) where {T}
    return copy(b.cons_reif)
end

function MOI.get(
    b::Conjunction2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.EqualTo{T},
    },
) where {T}
    return [b.con_conjunction]
end
