"""
Bridges `Count{F, S}`-in-`VectorAffineFunction`.
"""
struct CountFunctionBridge{T <: Real, F <: NL_SV_FCT, S <: MOI.AbstractScalarSet} <: MOIBC.AbstractBridge
    var::MOI.VariableIndex
    var_int::MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}
    nl::_NonlinearVectorFunction2VectorAffineFunction
    con::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Count{S}}
end

function MOIBC.bridge_constraint(
    ::Type{CountFunctionBridge{T, S}},
    model,
    f::CP.CountFunction{F, S},
    s::MOI.AbstractScalarSet,
) where {T, F, S}
    var, var_int = MOI.add_constrained_variable(model, MOI.Integer())

    fs, nl = _nl_vector_to_vaf{T}(f.array)

    con = MOI.add_constraint(
        model, 
        MOIU.vectorize(
            [
                MOI.SingleVariable(var),
                MOIU.scalarize(fs)...
            ]
        ),
        CP.Count(length(f.array), f.set)
    )

    return CountFunctionBridge(var, var_int, nl, con)
end

function MOI.supports_constraint(
    ::Type{CountFunctionBridge{T}},
    ::Union{Type{CP.CountFunction{T}}},
    ::Type{<: AbstractScalarSet},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{CountFunctionBridge{T}}) where {T}
    return [(MOI.Integer,)]
end

function MOIB.added_constraint_types(::Type{CountFunctionBridge{T, F, S}}) where {T, F, S}
    return [
        (MOI.VectorAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOI.get(::CountFunctionBridge, ::MOI.NumberOfVariables)
    return 1
end

# For each type of F-in-S constraint: 
function MOI.get(
    b::CountFunctionBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return length(b.assign_unique) + length(b.assign_number) + length(b.assign_load)
end

# Only if the bridge creates variables:
function MOI.get(
    b::CountFunctionBridge{T},
    ::MOI.ListOfVariableIndices,
)::Vector{MOI.VariableIndex} where {T}
    return vec(b.assign_var)
end

# For each type of F-in-S constraint: 
function MOI.get(
    b::CountFunctionBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return [b.assign_unique..., b.assign_number..., b.assign_load...]
end
