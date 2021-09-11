"""
Bridges `Function`-in-`Scalar` to `ScalarAffineFunction`-in-`Scalar`.
"""
struct FunctionBridge{T} <: MOIBC.AbstractBridge
    vars::Matrix{MOI.VariableIndex}
    cons::Matrix{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}}
    oths::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{FunctionBridge{T}},
    model,
    f::Function{T}, # Function to rewrite.
    s::MOI.AbstractScalarSet, # Any set
) where {T}
    # Create vars, cons, oths.

    return FunctionBridge(vars, cons, oths)
end

function MOI.supports_constraint(
    ::Type{FunctionBridge{T}},
    ::Union{Type{Function{T}}}, # Function to rewrite.
    ::Type{<: AbstractScalarSet}, # Any set
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{FunctionBridge{T}}) where {T}
    # The bridge creates variables:
    return [(MOI.ZeroOne,)]
    # The bridge does not create variables: 
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{FunctionBridge{T}}) where {T}
    return [
        # One element per F-in-S the bridge creates.
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

# Only if the bridge creates variables:
function MOI.get(b::FunctionBridge, ::MOI.NumberOfVariables)
    # The bridge creates variables:
    return length(b.assign_var)
end

# For each type of F-in-S constraint: 
function MOI.get(
    b::FunctionBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return length(b.assign_unique) + length(b.assign_number) + length(b.assign_load)
end

# Only if the bridge creates variables:
function MOI.get(
    b::FunctionBridge{T},
    ::MOI.ListOfVariableIndices,
)::Vector{MOI.VariableIndex} where {T}
    return vec(b.assign_var)
end

# For each type of F-in-S constraint: 
function MOI.get(
    b::FunctionBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return [b.assign_unique..., b.assign_number..., b.assign_load...]
end
