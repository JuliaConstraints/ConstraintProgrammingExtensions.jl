function _detect_variable_type(model::MOI.ModelLike, v::Union{MOI.SingleVariable, MOI.VariableIndex})
    # TODO: is this enough? Or should the code rather try all the countless possibilities?
    if is_integer(model, v) || is_binary(model, v)
        return Int
    else
        return Float64
    end
end

# -----------------------------------------------------------------------------
# - Detect whether a variable or a function has some properties.
# -----------------------------------------------------------------------------

function is_integer(model::MOI.ModelLike, v::MOI.SingleVariable)
    return is_integer(model, v.variable)
end

function is_integer(model::MOI.ModelLike, v::MOI.VariableIndex)
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}(v.value)
    return MOI.is_valid(model, c_idx)
end

function is_binary(model::MOI.ModelLike, v::MOI.SingleVariable)
    return is_binary(model, v.variable)
end

function is_binary(model::MOI.ModelLike, v::MOI.VariableIndex)
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}(v.value)
    return MOI.is_valid(model, c_idx)
end

function has_lower_bound(model::MOI.ModelLike, v::MOI.SingleVariable)
    return has_lower_bound(model, v.variable)
end

function has_lower_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction{T}) where {T <: Real}
    for t in v.terms
        if t.coefficient == zero(T)
            continue
        end
        if !has_lower_bound(model, t.variable_index)
            return false
        end
    end
    return true
end

function has_lower_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    T = _detect_variable_type(model, v)

    # Check if the variable has an explicit lower bound.
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{T}}(v.value)
    if MOI.is_valid(model, c_idx)
        return true
    end

    # Booleans have an implicit lower bound.
    if is_binary(model, v)
        return true
    end

    return false
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.SingleVariable)
    return has_upper_bound(model, v.variable)
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction{T}) where {T <: Real}
    for t in v.terms
        if t.coefficient == zero(T)
            continue
        end
        if !has_upper_bound(model, t.variable_index)
            return false
        end
    end
    return true
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    T = _detect_variable_type(model, v)

    # Check if the variable has an explicit upper bound.
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{T}}(v.value)
    if MOI.is_valid(model, c_idx)
        return true
    end

    # Booleans have an implicit upper bound.
    if is_binary(model, v)
        return true
    end

    return false
end

# -----------------------------------------------------------------------------
# - Get some properties about a variable or a function.
# -----------------------------------------------------------------------------

function get_lower_bound(model::MOI.ModelLike, v::MOI.SingleVariable)
    return get_lower_bound(model, v.variable)
end

function get_lower_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction{T}) where {T <: Real}
    if !has_lower_bound(model, v)
        # Return -Inf, cast to the right type. typemin(Float64) is exactly 
        # -Inf, the right values are returned for Float32 and for Float16.
        # No infinite available for other types than floats, though.
        return typemin(T)
    end

    lb = zero(T)
    for t in v.terms
        var_lb = get_lower_bound(model, t.variable_index)
        var_ub = get_upper_bound(model, t.variable_index)

        if t.coefficient == zero(T)
            continue
        elseif t.coefficient > zero(T)
            lb += t.coefficient * var_lb
        else # t.coefficient < zero(T)
            lb += t.coefficient * var_ub
        end
    end

    return lb
end

function get_lower_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    T = _detect_variable_type(model, v)

    if is_binary(model, v)
        return 0
    end

    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{T}}(
        v.value,
    )
    try
        return MOI.get(model, MOI.ConstraintSet(), c_idx).lower
    catch
        return typemin(T)
    end
end

function get_upper_bound(model::MOI.ModelLike, v::MOI.SingleVariable)
    return get_upper_bound(model, v.variable)
end

function get_upper_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction{T}) where {T <: Real}
    if !has_upper_bound(model, v)
        # Return Inf, cast to the right type. typemax(Float64) is exactly 
        # Inf, the right values are returned for Float32 and for Float16.
        # No infinite available for other types than floats, though.
        return typemax(T)
    end

    ub = zero(T)
    for t in v.terms
        var_lb = get_lower_bound(model, t.variable_index)
        var_ub = get_upper_bound(model, t.variable_index)

        if t.coefficient == zero(T)
            continue
        elseif t.coefficient > zero(T)
            ub += t.coefficient * var_ub
        else # t.coefficient < zero(T)
            ub += t.coefficient * var_lb
        end
    end

    return ub
end

function get_upper_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    T = _detect_variable_type(model, v)

    if is_binary(model, v)
        return 1
    end

    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{T}}(v.value)
    try
        return MOI.get(model, MOI.ConstraintSet(), c_idx).upper
    catch
        return typemax(T)
    end
end
