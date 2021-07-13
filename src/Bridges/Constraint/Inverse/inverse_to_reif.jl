"""
Bridges `CP.Inverse` to reification.
"""
struct Inverse2ReificationBridge{T} <: MOIBC.AbstractBridge
    vars_first::Matrix{MOI.VariableIndex}
    vars_first_bin::Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    vars_second::Matrix{MOI.VariableIndex}
    vars_second_bin::Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons_first_reif::Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}}}}
    cons_second_reif::Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}}}}
    cons_equivalence::Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{Inverse2ReificationBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Inverse,
) where {T}
    return MOIBC.bridge_constraint(
        Inverse2ReificationBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Inverse2ReificationBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Inverse,
) where {T}
    f_scalars = MOIU.scalarize(f)
    f_x = f_scalars[1:s.dimension]
    f_y = f_scalars[(s.dimension + 1):(2 * s.dimension)]

    vars_first = Matrix{MOI.VariableIndex}(undef, s.dimension, s.dimension)
    vars_first_bin = Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}(undef, s.dimension, s.dimension)
    vars_second = Matrix{MOI.VariableIndex}(undef, s.dimension, s.dimension)
    vars_second_bin = Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}(undef, s.dimension, s.dimension)

    for i in 1:s.dimension
        vars_first[i, :], vars_first_bin[i, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.dimension])
        vars_second[i, :], vars_second_bin[i, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.dimension])
    end

    #     x_i    =    j     ⟺    y_j    =    i
    # \___ vars1[i, j] ___/    \___ vars2[i, j] ___/

    cons_first_reif = Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}}}}(undef, s.dimension, s.dimension)
    cons_second_reif = Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}}}}(undef, s.dimension, s.dimension)
    cons_equivalence = Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}(undef, s.dimension, s.dimension)
    
    for i in 1:s.dimension
        for j in 1:s.dimension
            cons_first_reif[i, j] = MOI.add_constraint(
                model, 
                MOIU.vectorize(
                    [
                        one(T) * vars_first[i, j], 
                        f_x[i] - T(j)
                    ]
                ),
                CP.Reified(MOI.EqualTo(zero(T)))
            )

            cons_second_reif[i, j] = MOI.add_constraint(
                model, 
                MOIU.vectorize(
                    [
                        one(T) * vars_second[i, j], 
                        f_y[j] - T(i)
                    ]
                ),
                CP.Reified(MOI.EqualTo(zero(T)))
            )

            cons_equivalence[i, j] = MOI.add_constraint(
                model, 
                one(T) * vars_first[i, j] - one(T) * vars_second[i, j],
                MOI.EqualTo(zero(T))
            )
        end
    end

    return Inverse2ReificationBridge(vars_first, vars_first_bin, vars_second, vars_second_bin, cons_first_reif, cons_second_reif, cons_equivalence)
end

function MOI.supports_constraint(
    ::Type{Inverse2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Inverse},
) where {T}
    return true
    # Ideally, ensure that the underlying solver supports all the needed 
    # reified constraints.
end

function MOIB.added_constrained_variable_types(::Type{Inverse2ReificationBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Inverse2ReificationBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.VectorAffineFunction{T}, CP.Reified), # TODO: how to be more precise?
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{Inverse2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Inverse},
) where {T}
    return Inverse2ReificationBridge{T}
end

function MOI.get(::Inverse2ReificationBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 2
end

function MOI.get(
    ::Inverse2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return 2
end

function MOI.get(
    ::Inverse2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Reified,
    },
) where {T}
    return 2
end

function MOI.get(
    ::Inverse2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::Inverse2ReificationBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return [b.var_antecedent, b.var_consequent]
end

function MOI.get(
    b::Inverse2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return [b.var_antecedent_bin, b.var_consequent_bin]
end

function MOI.get(
    b::Inverse2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Reified,
    },
) where {T}
    return [b.con_reif_antecedent, b.con_reif_consequent]
end

function MOI.get(
    b::Inverse2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return [b.con_implication]
end
