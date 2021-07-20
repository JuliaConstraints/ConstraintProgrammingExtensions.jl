"""
Bridges `Count{F, S}`-in-`VectorAffineFunction`.
"""
struct CountFunctionBridge{T <: Real, F <: NL_SV_FCT, S <: MOI.AbstractScalarSet} <: MOIBC.AbstractBridge
    var::MOI.VariableIndex
    var_int::MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}
    var_nl::Vector{MOI.VariableIndex}
    var_nl_dom::Union{
        Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}},
        Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}},
    }
    var_nl_dom::Vector{MOI.ConstraintIndex}
    con_nl::Vector{MOI.ConstraintIndex} # (Nonlinear function) - single variable = 0
    con::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Count{S}}
end

function MOIBC.bridge_constraint(
    ::Type{CountFunctionBridge{T, S}},
    model,
    f::CP.CountFunction{F, S},
    s::MOI.AbstractScalarSet,
) where {T, F, S}
    var, var_int = MOI.add_constrained_variable(model, MOI.Integer())

    fs = MOI.ScalarAffineFunction{T}[]
    size_hint!(fs, length(f.array))

    var_nl = MOI.VariableIndex[]
    var_nl_dom = MOI.ConstraintIndex[]
    var_nl_con = MOI.ConstraintIndex[]

    for fa in f.array
        if CP.is_affine(model, fa)
            push!(fs, MOI.ScalarAffineFunction{T}(fa))
        else
            @static if T == Bool
                v, c = MOI.add_constrained_variable(model, MOI.ZeroOne())
                push!(var_nl, v)
                push!(var_nl_dom, c)
            elseif T <: Integer
                v, c = MOI.add_constrained_variable(model, MOI.Integer())
                push!(var_nl, v)
                push!(var_nl_dom, c)
            else
                v = MOI.add_constrained_variable(model)
                push!(var_nl, v)
            end

            c = MOI.add_constraint(
                model, 
                MOI.SingleVariable(v) - fa,
                MOI.EqualTo(zero(T))
            )
            push!(var_nl_con, c)
        end
    end

    con = MOI.add_constraint(
        model, 
        MOIU.vectorize(
            [
                MOI.SingleVariable(var),
                f.array...
            ]
        ),
        CP.Count(length(f.array), f.set)
    )

    return CountFunctionBridge(var, var_int, var_nl, var_nl_con, var_nl_con, con)
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
