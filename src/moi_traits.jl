function _detect_variable_type(model::MOI.ModelLike, v::MOI.VariableIndex)
    # TODO: is this enough? Or should the code rather try all the countless possibilities for T in the calling functions (based on the constraint types that are used in the model)?
    if is_integer(model, v) || is_binary(model, v)
        return Int
    else
        return Float64
    end
end

# -----------------------------------------------------------------------------
# - Detect whether a variable or a function has some properties.
# -----------------------------------------------------------------------------

function is_integer(model::MOI.ModelLike, v::MOI.VariableIndex)
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.Integer}(v.value)
    return MOI.is_valid(model, c_idx)
end

function is_integer(model::MOI.ModelLike, f::MOI.ScalarAffineFunction{T}) where {T <: Real}
    v = MOIU.canonical(f)
    for t in v.terms
        if !isinteger(t.coefficient) || !is_integer(model, t.variable)
            return false
        end
    end
    return true
end

function is_binary(model::MOI.ModelLike, v::MOI.VariableIndex)
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}(v.value)
    return MOI.is_valid(model, c_idx)
end

function is_binary(model::MOI.ModelLike, f::MOI.ScalarAffineFunction{T}) where {T <: Real}
    v = MOIU.canonical(f)

    # The sum of two variables cannot be ensured to be binary (at least, by 
    # simple bound checking).
    if length(v.terms) > 1
        return false
    end
    
    # Two cases: either just a binary variable, or its complement.
    t = v.terms[1]
    if t.coefficient === one(T)
        return f.constant == zero(T) && is_binary(model, t.variable)
    elseif t.coefficient === -one(T)
        return f.constant == one(T) && is_binary(model, t.variable)
    else
        return false
    end
end

function has_lower_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction{T}) where {T <: Real}
    for t in v.terms
        if t.coefficient == zero(T)
            continue
        end
        if !has_lower_bound(model, t.variable)
            return false
        end
    end
    return true
end

function has_lower_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    T = _detect_variable_type(model, v)

    # TODO: should infinite values be disregarded? 

    # Check if the variable has an explicit lower bound.
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.GreaterThan{T}}(v.value)
    if MOI.is_valid(model, c_idx)
        return true
    end

    # Check if the variable has an interval.
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.Interval{T}}(v.value)
    if MOI.is_valid(model, c_idx)
        return true
    end

    # Booleans have an implicit lower bound.
    if is_binary(model, v)
        return true
    end

    return false
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction{T}) where {T <: Real}
    for t in v.terms
        if t.coefficient == zero(T)
            continue
        end
        if !has_upper_bound(model, t.variable)
            return false
        end
    end
    return true
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    T = _detect_variable_type(model, v)

    # TODO: should infinite values be disregarded? 

    # Check if the variable has an explicit upper bound.
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.LessThan{T}}(v.value)
    if MOI.is_valid(model, c_idx)
        return true
    end

    # Check if the variable has an interval.
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.Interval{T}}(v.value)
    if MOI.is_valid(model, c_idx)
        return true
    end

    # Booleans have an implicit upper bound.
    if is_binary(model, v)
        return true
    end

    return false
end

# function is_affine(::MOI.ModelLike, ::MOI.VariableIndex)
#     return true
# end

# function is_affine(::MOI.ModelLike, ::MOI.ScalarAffineFunction{T}) where {T}
#     return true
# end

# function is_affine(::MOI.ModelLike, ::MOI.VectorOfVariables)
#     return true
# end

# function is_affine(::MOI.ModelLike, ::MOI.VectorAffineFunction{T}) where {T}
#     return true
# end

# function is_affine(::MOI.ModelLike, ::Any)
#     return false
# end

# -----------------------------------------------------------------------------
# - Get some properties about a variable or a function.
# -----------------------------------------------------------------------------

function get_lower_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction{T}) where {T <: Real}
    if !has_lower_bound(model, v)
        # Return -Inf, cast to the right type. typemin(Float64) is exactly 
        # -Inf, the right values are returned for Float32 and for Float16.
        # No infinite available for other types than floats, though.
        return typemin(T)
    end

    lb = zero(T)
    for t in v.terms
        var_lb = get_lower_bound(model, t.variable)
        var_ub = get_upper_bound(model, t.variable)

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

    # Booleans have an implicit lower bound.
    if is_binary(model, v)
        return 0
    end

    # Check if the variable has an explicit lower bound.
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.GreaterThan{T}}(
        v.value,
    )
    if MOI.is_valid(model, c_idx)
        return MOI.get(model, MOI.ConstraintSet(), c_idx).lower
    end

    # Check if the variable has an interval.
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.Interval{T}}(v.value)
    if MOI.is_valid(model, c_idx)
        return MOI.get(model, MOI.ConstraintSet(), c_idx).lower
    end

    return typemin(T)
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
        var_lb = get_lower_bound(model, t.variable)
        var_ub = get_upper_bound(model, t.variable)

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

    # Booleans have an implicit upper bound.
    if is_binary(model, v)
        return 1
    end

    # Check if the variable has an explicit lower bound.
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.LessThan{T}}(
        v.value,
    )
    if MOI.is_valid(model, c_idx)
        return MOI.get(model, MOI.ConstraintSet(), c_idx).upper
    end

    # Check if the variable has an interval.
    c_idx = MOI.ConstraintIndex{MOI.VariableIndex, MOI.Interval{T}}(v.value)
    if MOI.is_valid(model, c_idx)
        return MOI.get(model, MOI.ConstraintSet(), c_idx).upper
    end

    return typemax(T)
end
