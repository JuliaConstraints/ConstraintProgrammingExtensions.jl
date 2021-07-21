# Transform a Vector{<: MOI.AbstractScalarFunction} into a 
# VectorAffineFunction, i.e. adds a series of variables, domains, and constraints.
# If the input vector of functions is only made of affine functions, a vector
# affine function is returned, without any new variable or constraint.

# Important: the input is a vector of scalar functions, and not a vector 
# function, i.e. all elements of the vector can be represented by a simple 
# variable.

struct _NonlinearVectorFunction2VectorAffineFunction
    vars::Vector{MOI.VariableIndex}
    doms::Vector{MOI.ConstraintIndex} # Typically, just ZeroOne or Integer constraints.
    cons::Vector{MOI.ConstraintIndex} # (Nonlinear function) - single variable = 0
end

function _nl_vector_to_vaf{T}(lf::Vector{F}) where {F <: MOI.AbstractScalarFunction, T <: Number}
    fs = MOI.ScalarAffineFunction{T}[]
    size_hint!(fs, length(lf))

    vars = MOI.VariableIndex[]
    doms = MOI.ConstraintIndex[]
    cons = MOI.ConstraintIndex[]

    for f in lf
        if CP.is_affine(model, f)
            push!(fs, MOI.ScalarAffineFunction{T}(f))
        else
            @static if T == Bool
                v, c = MOI.add_constrained_variable(model, MOI.ZeroOne())
                push!(vars, v)
                push!(doms, c)
            elseif T <: Integer
                v, c = MOI.add_constrained_variable(model, MOI.Integer())
                push!(vars, v)
                push!(doms, c)
            else
                v = MOI.add_constrained_variable(model)
                push!(vars, v)
            end
            push!(fs, MOI.ScalarAffineFunction{T}(f))

            c = MOI.add_constraint(
                model, 
                MOI.SingleVariable(v) - f,
                MOI.EqualTo(zero(T))
            )
            push!(cons, c)
        end
    end

    return MOIU.vectorize(fs), _NonlinearVectorFunction2VectorAffineFunction(vars, doms, cons)
end
