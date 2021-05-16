function is_integer(model::MOI.AbstractModel, v::MOI.SingleVariable)
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}(v.variable)
    return MOI.is_valid(model, c_idx)
end

function is_binary(model::MOI.AbstractModel, v::MOI.SingleVariable)
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}(v.variable)
    return MOI.is_valid(model, c_idx)
end

function has_lower_bound(model::MOI.AbstractModel, v::MOI.SingleVariable)
    # TODO: not just Float64.
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{Float64}}(v.variable)
    return MOI.is_valid(model, c_idx)
end

function has_upper_bound(model::MOI.AbstractModel, v::MOI.SingleVariable)
    # TODO: not just Float64.
    c_idx = MOI.ConstraintIndex{MOI.SingleVariable, MOI.LessThan{Float64}}(v.variable)
    return MOI.is_valid(model, c_idx)
end
