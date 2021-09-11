"""
Bridges `CP.Disjunction` to reification.
"""
struct Disjunction2ReificationBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}}
    cons_reif::Vector{MOI.ConstraintIndex}
    # Ideally, Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reification{<: MOI.AbstractSet}}}, 
    # but Julia has no notion of type erasure.
    con_disjunction::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Disjunction2ReificationBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Disjunction{S},
) where {T, S}
    return MOIBC.bridge_constraint(
        Disjunction2ReificationBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Disjunction2ReificationBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Disjunction{S},
) where {T, S}
    vars, vars_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:length(s.constraints)])

    f_scalars = MOIU.scalarize(f)
    cons_reif = Vector{MOI.ConstraintIndex}(undef, length(s.constraints))
    cur_dim = 1
    for i in 1:length(s.constraints)
        cons_reif[i] = MOI.add_constraint(
            model,
            MOIU.vectorize(
                [
                    one(T) * vars[i],
                    f_scalars[cur_dim : (cur_dim + MOI.dimension(s.constraints[i]) - 1)]...,
                ]
            ),
            CP.Reification(s.constraints[i])
        )
        cur_dim += MOI.dimension(s.constraints[i])
    end

    con_disjunction = MOI.add_constraint(
        model, 
        sum(one(T) .* MOI.VariableIndex.(vars)),
        MOI.GreaterThan(one(T))
    )

    return Disjunction2ReificationBridge(vars, vars_bin, cons_reif, con_disjunction)
end

function MOI.supports_constraint(
    ::Type{Disjunction2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Disjunction{S}},
) where {T, S}
    return true
    # Ideally, ensure that the underlying solver supports all the needed 
    # reified constraints:
    # return all(MOI.supports_constraint(model, type, CP.Reification{C}) for C in S.parameters)
end

function MOIB.added_constrained_variable_types(::Type{Disjunction2ReificationBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Disjunction2ReificationBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Reification), # TODO: how to be more precise?
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
    ]
end

function MOI.get(b::Disjunction2ReificationBridge{T}, ::MOI.NumberOfVariables) where {T}
    return length(b.vars)
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VariableIndex, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_bin)
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Reification,
    },
) where {T}
    return length(b.cons_reif)
end

function MOI.get(
    ::Disjunction2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return copy(b.vars)
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VariableIndex, MOI.ZeroOne,
    },
) where {T}
    return copy(b.vars_bin)
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Reification,
    },
) where {T}
    return copy(b.cons_reif)
end

function MOI.get(
    b::Disjunction2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return [b.con_disjunction]
end
