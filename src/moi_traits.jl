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

function has_lower_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    # TODO: not just Float64.
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}}(v.value)
    return MOI.is_valid(model, c_idx)
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.SingleVariable)
    return has_upper_bound(model, v.variable)
end

function has_upper_bound(model::MOI.ModelLike, v::MOI.VariableIndex)
    # TODO: not just Float64.
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}}(v.value)
    return MOI.is_valid(model, c_idx)
end
