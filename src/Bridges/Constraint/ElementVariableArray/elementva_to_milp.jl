"""
Bridges `CP.ElementVariableArray` to MILP constraints by using a unary 
encoding of the index in the array.
"""
struct ElementVariableArray2MILPBridge{T} <: MOIBC.AbstractBridge
    vars_unary::Vector{MOI.VariableIndex}
    vars_unary_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    vars_product::Vector{MOI.VariableIndex}
    vars_product_int::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}}

    con_unary::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_choose_one::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_value::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_product_lt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
    con_product_gt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{ElementVariableArray2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.ElementVariableArray,
) where {T}
    return MOIBC.bridge_constraint(
        ElementVariableArray2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ElementVariableArray2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.ElementVariableArray,
) where {T}
    f_scalars = MOIU.scalarize(f)
    f_value = f_scalars[1]
    f_index = f_scalars[2]
    f_array = f_scalars[3:end]
    
    for i in 1:s.dimension
        @assert CP.has_lower_bound(model, f_array[i])
        @assert CP.has_upper_bound(model, f_array[i])
    end

    # Create the new variables
    vars_unary, vars_unary_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.dimension])

    if T <: Integer
        vars_product, vars_product_int = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:s.dimension])
    else
        vars_product = MOI.add_variables(model, s.dimension)
        vars_product_int = MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}[]
    end

    # Unary decomposition of the index.
    con_unary = MOI.add_constraint(
        model, 
        sum(T(i) * MOI.SingleVariable(vars_unary[i]) for i in 1:s.dimension) - f_index,
        MOI.EqualTo(zero(T))
    )

    con_choose_one = MOI.add_constraint(
        model, 
        sum(one(T) .* MOI.SingleVariable.(vars_unary)),
        MOI.EqualTo(one(T))
    )

    # Write the new value as a sum of products: 
    #     value = ∑_i vars_unary[i] * f_array[i]
    #                 \________________________/
    #                       vars_product[i]
    con_value = MOI.add_constraint(
        model, 
        sum(one(T) .* MOI.SingleVariable.(vars_product)) - f_value,
        MOI.EqualTo(zero(T))
    )

    # Constrain the product variables.
    big_m = T[
        max(
            abs(CP.get_upper_bound(model, f_array[i])), 
            abs(CP.get_lower_bound(model, f_array[i])), 
        )
        for i in 1:s.dimension
    ]

    con_product_lt = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}[
        MOI.add_constraint(
            model, 
            MOI.SingleVariable(vars_product[i]) - big_m[i] * MOI.SingleVariable(vars_unary[i]),
            MOI.LessThan(zero(T))
        )
        for i in 1:s.dimension
    ]

    con_product_gt = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}[
        MOI.add_constraint(
            model, 
            MOI.SingleVariable(vars_product[i]) - f_array[i] + big_m[i] * MOI.SingleVariable(vars_unary[i]),
            MOI.GreaterThan(big_m[i])
        )
        for i in 1:s.dimension
    ]

    return ElementVariableArray2MILPBridge(vars_unary, vars_unary_bin, vars_product, vars_product_int, con_unary, con_choose_one, con_value, con_product_lt, con_product_gt)
end

function MOI.supports_constraint(
    ::Type{ElementVariableArray2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.ElementVariableArray},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ElementVariableArray2MILPBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constrained_variable_types(::Type{ElementVariableArray2MILPBridge{T}}) where {T <: Integer}
    return [(MOI.ZeroOne,), (MOI.Integer,)]
end

function MOIB.added_constraint_types(::Type{ElementVariableArray2MILPBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIB.added_constraint_types(::Type{ElementVariableArray2MILPBridge{T}}) where {T <: Integer}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.SingleVariable, MOI.Integer),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{ElementVariableArray2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.ElementVariableArray},
) where {T}
    return ElementVariableArray2MILPBridge{T}
end

function MOI.get(b::ElementVariableArray2MILPBridge{T}, ::MOI.NumberOfVariables) where {T}
    return length(b.vars_unary) + length(b.vars_product)
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_unary_bin)
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.Integer,
    },
) where {T}
    return length(b.vars_product_int)
end

function MOI.get(
    ::ElementVariableArray2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return 3
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.con_product_lt)
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return length(b.con_product_gt)
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return vcat(b.vars_unary, b.vars_product)
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return b.vars_unary_bin
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.Integer,
    },
) where {T}
    return b.vars_product_int
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return [b.con_unary, b.con_choose_one, b.con_value]
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return b.con_product_lt
end

function MOI.get(
    b::ElementVariableArray2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return b.con_product_gt
end
