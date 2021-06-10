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

function has_lower_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction)
    return all(has_lower_bound(model, t.variable_index) for t in v.terms) 
end

function has_lower_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    # TODO: not just Float64.
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}}(
        v.value,
    )
    return MOI.is_valid(model, c_idx)
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.SingleVariable)
    return has_upper_bound(model, v.variable)
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction)
    return all(has_upper_bound(model, t.variable_index) for t in v.terms) 
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    # TODO: not just Float64.
    c_idx =
        MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}}(v.value)
    return MOI.is_valid(model, c_idx)
end

# -----------------------------------------------------------------------------
# - Get some properties about a variable or a function.
# -----------------------------------------------------------------------------

function get_lower_bound(model::MOI.ModelLike, v::MOI.SingleVariable)
    return get_lower_bound(model, v.variable)
end

function get_lower_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction)
    lb = zero(Float64)
    for t in v.terms
        var_lb = get_lower_bound(model, t.variable_index)
        var_ub = get_upper_bound(model, t.variable_index)

        if t.coefficient == 0
            continue
        elseif t.coefficient > 0
            lb += t.coefficient + var_lb
        else # t.coefficient < 0
            lb += t.coefficient + var_ub
        end
    end

    return lb
end

function get_lower_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    # TODO: not just Float64.
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}}(
        v.value,
    )
    set = MOI.get(model, MOI.ConstraintSet(), c_idx)
    return set.lower
end

function get_upper_bound(model::MOI.ModelLike, v::MOI.SingleVariable)
    return get_upper_bound(model, v.variable)
end

function get_upper_bound(model::MOI.ModelLike, v::MOI.ScalarAffineFunction)
    ub = zero(Float64)
    for t in v.terms
        var_lb = get_lower_bound(model, t.variable_index)
        var_ub = get_upper_bound(model, t.variable_index)

        if t.coefficient == 0
            continue
        elseif t.coefficient > 0
            ub += t.coefficient + var_ub
        else # t.coefficient < 0
            ub += t.coefficient + var_lb
        end
    end

    return ub
end

function get_upper_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    # TODO: not just Float64.
    c_idx =
        MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}}(v.value)
    set = MOI.get(model, MOI.ConstraintSet(), c_idx)
    return set.upper
end
