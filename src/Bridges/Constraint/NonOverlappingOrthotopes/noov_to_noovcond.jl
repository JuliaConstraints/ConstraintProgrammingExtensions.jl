"""
Bridges `CP.NonOverlappingOrthotopes{CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}` to 
`CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES}`.
"""
struct NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T} <: MOIBC.AbstractBridge
    var::MOI.VariableIndex
    var_con::MOI.ConstraintIndex{MOI.VariableIndex, MOI.EqualTo{T}}
    con::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES}}
end

function MOIBC.bridge_constraint(
    ::Type{NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.NonOverlappingOrthotopes{CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}
) where {T}
    return MOIBC.bridge_constraint(
        NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.NonOverlappingOrthotopes{CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}
) where {T}
    f_scalars = MOIU.scalarize(f)

    # One new variable that takes the value "true".
    var, var_con = MOI.add_constrained_variable(model, MOI.EqualTo(one(T)))

    # The equivalent 
    # NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES} with 
    # the conditions set to true.
    new_f = MOI.ScalarAffineFunction{T}[]
    j = 1
    for _ in 1:s.n_orthotopes
        for _ in 1:(3 * s.n_dimensions)
            push!(new_f, f_scalars[j])
            j += 1
        end
        push!(new_f, one(T) * var)
    end
    new_f = MOIU.vectorize(new_f)

    con = MOI.add_constraint(
        model, 
        new_f,
        CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES}(s.n_orthotopes, s.n_dimensions)
    )

    return NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge(var, var_con, con)
end

function MOI.supports_constraint(
    ::Type{NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.NonOverlappingOrthotopes{CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T}}) where {T}
    return [(MOI.EqualTo{T},)]
end

function MOIB.added_constraint_types(::Type{NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES}),
    ]
end

function MOI.get(::NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge, ::MOI.NumberOfVariables)
    return 1
end

function MOI.get(
    ::NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VariableIndex, MOI.EqualTo{T},
    },
) where {T}
    return 1
end

function MOI.get(
    ::NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES},
    },
) where {T}
    return 1
end

function MOI.get(
    b::NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return [b.var]
end

function MOI.get(
    b::NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VariableIndex, MOI.EqualTo{T},
    },
) where {T}
    return [b.var_con]
end

function MOI.get(
    b::NonOverlappingOrthotopes2ConditionallyNonOverlappingOrthotopesBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.NonOverlappingOrthotopes{CP.CONDITIONAL_NONVERLAPPING_ORTHOTOPES},
    },
) where {T}
    return [b.con]
end
