"""
Bridges `Origin` to `Dest`.
"""
struct Origin2DestBridge{T} <: MOIBC.AbstractBridge
    vars::Matrix{MOI.VariableIndex}
    cons::Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    oths::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{Origin2DestBridge{T}},
    model,
    f::MOI.VectorOfVariables, # Simple function
    s::CP.BinPacking{T}, # Dest
) where {T}
    return MOIBC.bridge_constraint(
        Origin2DestBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Origin2DestBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T}, # More complex function
    s::CP.BinPacking{T}, # Dest
) where {T}
    # Create vars, cons, oths.

    return Origin2DestBridge(vars, cons, oths)
end

function MOI.supports_constraint(
    ::Type{Origin2DestBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}}, # Functions for which there is a bridge_constraint.
    ::Type{CP.BinPacking{T}}, # Dest
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Origin2DestBridge{T}}) where {T}
    # The bridge creates variables:
    return [(MOI.ZeroOne,)]
    # The bridge does not create variables: 
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{Origin2DestBridge{T}}) where {T}
    return [
        # One element per F-in-S the bridge creates.
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

# Only if the bridge creates variables:
function MOI.get(b::Origin2DestBridge, ::MOI.NumberOfVariables)
    # The bridge creates variables:
    return length(b.assign_var)
end

# For each type of F-in-S constraint: 
function MOI.get(
    b::Origin2DestBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return length(b.assign_unique) + length(b.assign_number) + length(b.assign_load)
end

# Only if the bridge creates variables:
function MOI.get(
    b::Origin2DestBridge{T},
    ::MOI.ListOfVariableIndices,
)::Vector{MOI.VariableIndex} where {T}
    return vec(b.assign_var)
end

# For each type of F-in-S constraint: 
function MOI.get(
    b::Origin2DestBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return [b.assign_unique..., b.assign_number..., b.assign_load...]
end
