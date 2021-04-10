module FlatZinc

import MathOptInterface
import ConstraintProgrammingExtensions

const MOI = MathOptInterface
const MOIU = MOI.Utilities
const CleverDicts = MOIU.CleverDicts
const CP = ConstraintProgrammingExtensions

# Formal grammar: https://www.minizinc.org/doc-2.5.5/en/fzn-spec.html#grammar

# =============================================================================
# =
# = FlatZinc model.
# =
# =============================================================================

mutable struct VariableInfo 
    index::MOI.VariableIndex
    name::String
    set::AbstractVector{MOI.AbstractSet}
end

mutable struct ConstraintInfo 
    index::MOI.ConstraintIndex
    # FlatZinc does not allow constraint names.
    f::MOI.AbstractFunction
    s::AbstractVector{MOI.AbstractSet}
    output_as_part_of_variable::Bool
end

mutable struct Optimizer <: MOI.AbstractOptimizer
    # A mapping from the MOI.VariableIndex to the variable object.
    # VariableInfo also stores some additional fields like the type of variable.
    variable_info::CleverDicts.CleverDict{MOI.VariableIndex, VariableInfo}

    # A mapping from the MOI.ConstraintIndex to the variable object.
    # VariableInfo also stores some additional fields like the type of variable.
    constraint_info::Dict{MOI.ConstraintIndex, ConstraintInfo}

    # Memorise the objective sense and the function separately.
    # The function can only be a single variable, as per FlatZinc limitations.
    objective_sense::MOI.OptimizationSense
    objective_function::Union{Nothing, MOI.SingleVariable}

    """
        Optimizer()

    Create a new Optimizer object.
    """
    function Optimizer()
        model.variable_info =
            CleverDicts.CleverDict{MOI.VariableIndex, VariableInfo}()
        model.constraint_info = Dict{MOI.ConstraintIndex, ConstraintInfo}()

        model.objective_sense = MOI.FEASIBILITY_SENSE
        model.objective_function = nothing

        MOI.empty!(model)
        return model
    end
end

function Base.show(io::IO, ::Optimizer)
    print(io, "A FlatZinc (fzn) model")
    return
end

function MOI.empty!(model::Optimizer)
    empty!(model.variable_info)
    empty!(model.constraint_info)

    model.objective_sense = MOI.FEASIBILITY_SENSE
    model.objective_function = nothing
    
    return
end

function MOI.is_empty(model::Optimizer)
    !isempty(model.variable_info) && return false
    !isempty(model.constraint_info) && return false
    model.objective_sense != MOI.FEASIBILITY_SENSE && return false
    model.objective_function !== nothing && return false
    return true
end

function _create_variable(model::Optimizer, set::MOI.AbstractScalarSet)
    index = CleverDicts.add_item(
        model.variable_info,
        VariableInfo(MOI.VariableIndex(0), "", set),
    )
    model.variable_info[index].index = index
    return index
end

function _create_constraint(model::Optimizer, f::MOI.SingleVariable, 
                            set::MOI.AbstractScalarSet, as_part_of_variable::Bool)
    index = CleverDicts.add_item(
        model.constraint_info,
        ConstraintInfo(MOI.ConstraintIndex(0), f, set, as_part_of_variable),
    )
    model.constraint_info[index].index = index
    return index
end

# Names. 
# No support for constraint names in fzn, hence no ConstraintName.

function MOI.get(model::Optimizer, ::MOI.VariableName, v::MOI.VariableIndex)
    return model.variable_info[v].name
end

function MOI.set(
    model::Optimizer,
    ::MOI.VariableName,
    v::MOI.VariableIndex,
    name::String,
)
    model.variable_info[v].name = name
    return
end

# Variables.

function supports_add_constrained_variables(
    ::Optimizer,
    ::Type{F},
) where {
    F <: Union{
        MOI.EqualTo{Float64},
        MOI.LessThan{Float64},
        MOI.GreaterThan{Float64},
        MOI.Interval{Float64},
        MOI.EqualTo{Int},
        MOI.LessThan{Int},
        MOI.GreaterThan{Int},
        MOI.Interval{Int},
        MOI.EqualTo{Bool},
        MOI.ZeroOne,
        MOI.Integer,
    },
}
    return true
end

function add_constrained_variables(model::Optimizer, sets::AbstractVector{<:MOI.AbstractScalarSet})
    # TODO: memorise that these variables are part of the same call, so that 
    # the generated FlatZinc is shorter (array of variables)? This would 
    # require that all sets are identical, though.
    vidx = [_create_variable(model, sets[i]) for i in 1:length(sets)]
    cidx = [_create_constraint(model, MOI.SingleVariable(vidx[i]), sets[i], true) for i in 1:length(sets)]
    return vidx, cidx
end

function add_constrained_variable(model::Optimizer, set::MOI.AbstractScalarSet)
    vidx = _create_variable(model, set)
    cidx = _create_constraint(model, MOI.SingleVariable(vidx), set, true)
    return vidx, cidx
end

# Constraints.

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{F, S},
) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    info = get(model.constraint_info, c, nothing)
    return info !== nothing && typeof(info.s) == S
end

function MOI.add_constraint(
    model::Optimizer,
    f::F,
    s::S,
) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    index = MOI.ConstraintIndex{F, S}(length(model.constraint_info) + 1)
    model.constraint_info[index] = ConstraintInfo(index, f, s, true)
    return index
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{F, S},
) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    return model.constraint_info[c].f
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{F, S},
) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    return model.constraint_info[c].set
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{F},
    ::Type{S},
) where {
    T <: Real,
    F <: Union{MOI.SingleVariable, MOI.ScalarAffineFunction{T}, MOI.ScalarQuadraticFunction{T}},
    S <: Union{MOI.GreaterThan{T}, MOI.LessThan{T}, MOI.EqualTo{T}},
}
    return true
end

# =============================================================================
# =
# = Export to the FlatZinc format.
# =
# =============================================================================

"""
    Base.write(io::IO, model::FlatZinc.Optimizer)

Write `model` to `io` in the FlatZinc (fzn) file format.
"""
function Base.write(io::IO, model::Optimizer)
    MOI.FileFormats.create_unique_names(model)

    write_variables(io, model)
    write_constraints(io, model)
    write_objective(io, model)

    return
end

function write_variables(io::IO, model::Optimizer)
    for var in model.variable_info
        # Variables either start with "var" or "array of var", let write_variable decide.
        write_variable(io, var.name, var.set)
        println(io)
    end
    println(io)
end

function write_constraints(io::IO, model::Optimizer)
    for cons in model.constraint_info
        if !cons.output_as_part_of_variable
            print(io, "constraint ")
            write_constraint(io, cons.f, cons.s)
            print(";")
            println(io)
        end
    end
    println(io)
end

# Variable printing.

function write_variable(io::IO, name::String, s::MOI.EqualTo{Float64})
    print(io, "var float: $(name) = $(s.value);")
end

function write_variable(io::IO, name::String, s::MOI.EqualTo{Int})
    print(io, "var int: $(name) = $(s.value);")
end

function write_variable(io::IO, name::String, s::MOI.EqualTo{Bool})
    print(io, "var bool: $(name) = $(s.value);")
end

function write_variable(io::IO, name::String, s::MOI.LessThan{Float64})
    # typemin(Float64) is -Inf, which is "-Inf" as a string. Take the next 
    # smallest value as a proxy, because it has a standard scientific notation.
    print(io, "var $(nextfloat(typemin(Float64)))..$(s.upper): $(name);")
end

function write_variable(io::IO, name::String, s::MOI.LessThan{Int})
    print(io, "var $(typemin(Int))..$(s.upper): $(name);")
end

function write_variable(io::IO, name::String, s::MOI.GreaterThan{Float64})
    # typemax(Float64) is Inf, which is "Inf" as a string. Take the next 
    # largest value as a proxy, because it has a standard scientific notation.
    print(io, "var $(s.lower)..$(prevfloat(typemax(Float64))): $(name);")
end

function write_variable(io::IO, name::String, s::MOI.GreaterThan{Int})
    print(io, "var $(s.lower)..$(typemax(Int)): $(name);")
end

function write_variable(io::IO, name::String, s::MOI.Interval{T}) where T <: Union{Int, Float64}
    print(io, "var $(s.lower)..$(s.upper): $(name);")
end

function write_variable(io::IO, name::String, ::MOI.ZeroOne)
    print(io, "var bool: $(name);")
end

function write_variable(io::IO, name::String, ::MOI.Integer)
    print(io, "var bool: $(name);")
end

# Constraint printing.
# Based on the built-in predicates: https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html
# In the same order as the documentation.

# - Integer constraints.
    # TODO: only for integer variables, not enforced for now.

function write_constraint(io::IO, model::Optimizer, f::MOI.VectorOfVariables, s::CP.Element{Int})
    @assert output_dimension(f) == 2
    value = f.variables[1]
    index = f.variables[2]
    print(io, "array_int_element($(_fzn_f(model, index)), $s.values, $(_fzn_f(model, value)))")
end

function write_constraint(io::IO, model::Optimizer, f::MOI.VectorOfVariables, ::CP.MaximumAmong)
    array = f.variables[2:end]
    value = f.variables[1]
    print(io, "array_int_maximum($(_fzn_f(model, value)), $(_fzn_f(model, array)))")
end

function write_constraint(io::IO, model::Optimizer, f::MOI.VectorOfVariables, ::CP.MinimumAmong)
    array = f.variables[2:end]
    value = f.variables[1]
    print(io, "array_int_minimum($(_fzn_f(model, value)), $(_fzn_f(model, array)))")
end

# TODO: absolute value. int_abs.
# TODO: integer division. int_div

# int_eq, int_eq_reif: meaningless for MOI, no way to represent "x == y" 
# natively (goes through affine expressions).

function write_constraint(io::IO, model::Optimizer, f::MOI.SingleVariable, s::MOI.LessThan{Int})
    print(io, "int_le($(_fzn_f(model, f)), $(s.upper))")
end

# TODO: int_le_reif

function write_constraint(io::IO, model::Optimizer, f::MOI.ScalarAffineFunction, s::MOI.EqualTo{Int})
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    print(io, "int_lin_eq($(coefficients), [$(_fzn_f(model, variables))], $(value))")
end

# TODO: int_lin_eq_reif

function write_constraint(io::IO, model::Optimizer, f::MOI.ScalarAffineFunction, s::MOI.LessThan{Int})
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    print(io, "int_lin_le($(coefficients), [$(_fzn_f(model, variables))], $(value))")
end

# TODO: int_lin_le_reif

function write_constraint(io::IO, model::Optimizer, f::MOI.ScalarAffineFunction, s::CP.DifferentFrom{Int})
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    print(io, "int_lin_ne($(coefficients), [$(_fzn_f(model, variables))], $(value))")
end

# TODO: int_lin_ne_reif

function write_constraint(io::IO, model::Optimizer, f::MOI.SingleVariable, s::CP.Strictly{MOI.LessThan{Int}})
    print(io, "int_lt($(_fzn_f(model, f)), $(s.upper))")
end

# TODO: int_lt_reif
# TODO: int_max (CP equivalent!?)
# TODO: int_min (CP equivalent!?)
# TODO: int_mod, modulo

# int_ne, int_ne_reif: meaningless for MOI, no way to represent "x == y"
# natively (goes through affine expressions).

# TODO: int_pow.
# TODO: int_times.

function write_constraint(io::IO, model::Optimizer, f::MOI.SingleVariable, s::CP.Domain{Int})
    print(io, "set_in($(_fzn_f(model, f)), $(s.values))")
end

function write_constraint(io::IO, model::Optimizer, f::MOI.SingleVariable, s::MOI.GreaterThan{Int}) # In examples, but not in fzn doc? 
    print(io, "int_ge($(_fzn_f(model, f)), $(s.lower))")
end

function write_constraint(io::IO, model::Optimizer, f::MOI.SingleVariable, s::CP.Strictly{MOI.GreaterThan{Int}}) # In examples, but not in fzn doc? 
    print(io, "int_gt($(_fzn_f(model, f)), $(s.lower))")
end

# - Boolean constraints.

# TODO: array_bool_and, no conjunction between variables for now in CP.

function write_constraint(io::IO, model::Optimizer, f::MOI.VectorOfVariables, s::CP.Element{Bool})
    @assert output_dimension(f) == 2
    value = f.variables[1]
    index = f.variables[2]
    print(io, "array_bool_element($(_fzn_f(model, index)), $s.values, $(_fzn_f(model, value)))")
end

# TODO: array_bool_or, no disjunction between variables for now in CP.
# TODO: array_bool_xor, no XOR for now in CP.
# TODO: array_var_bool_element, no CP.Element for array of variables.
# TODO: bool2int, not in CP for now.
# TODO: bool_and, like array_bool_and.
# TODO: bool_clause, not in CP for now.

# bool_eq, bool_eq_reif: meaningless for MOI, no way to represent "x == y"
# natively (goes through affine expressions).
# bool_le, bool_le_reif: meaningless for MOI, no way to represent "x <= y"
# natively (goes through affine expressions).

# TODO: bool_lin_eq, bool_lin_le, no way to dispatch on the type of the variables.

# bool_lt, bool_lt_reif: meaningless for MOI, no way to represent "x < y"
# natively (goes through affine expressions).
# bool_ne, bool_ne_reif: meaningless for MOI, no way to represent "x != y"
# natively (goes through affine expressions).

# TODO: bool_or, no disjunction between variables for now in CP.
# TODO: bool_xor, no XOR between variables for now in CP.

# - Set constraints.

# TODO: no notion of set in MOI! 

# - Float constraints.

function write_constraint(io::IO, model::Optimizer, f::MOI.VectorOfVariables, s::CP.Element{Float64})
    @assert output_dimension(f) == 2
    value = f.variables[1]
    index = f.variables[2]
    print(io, "array_float_element($(_fzn_f(model, index)), $s.values, $(_fzn_f(model, value)))")
end

# TODO: no dispatch possible! Already taken by the integer version.
# function write_constraint(io::IO, model::Optimizer, f::MOI.VectorOfVariables, ::CP.MaximumAmong)
#     array = f.variables[2:end]
#     value = f.variables[1]
#     print(io, "array_float_maximum($(_fzn_f(model, value)), $(_fzn_f(model, array)))")
# end

# TODO: no dispatch possible! Already taken by the integer version.
# function write_constraint(io::IO, model::Optimizer, f::MOI.VectorOfVariables, ::CP.MinimumAmong)
#     array = f.variables[2:end]
#     value = f.variables[1]
#     print(io, "array_float_minimum($(_fzn_f(model, value)), $(_fzn_f(model, array)))")
# end

# TODO: array_var_float_element, i.e. CP.Element with a variable array.

# TODO: float_abs, float_acos, float_acosh, float_asin, float_asinh, 
# float_atan, float_atanh, float_cos, float_cosh, float_div. 

# float_dom: could be useful to merge several MOI.Interval as one constraint, 
# for now several float_in.

# float_eq, float_eq_reif: meaningless for MOI, no way to represent "x == y"
# natively (goes through affine expressions).

# TODO: float_exp

function write_constraint(io::IO, model::Optimizer, f::MOI.SingleVariable, s::MOI.Interval{Float64})
    print(io, "float_in($(_fzn_f(model, f)), [$s.lower, $s.upper])")
end

# TODO: float_in_reif

# float_le, float_le_reif: meaningless for MOI, no way to represent "x <= y"
# natively (goes through affine expressions).

function write_constraint(io::IO, model::Optimizer, f::MOI.ScalarAffineFunction, s::MOI.EqualTo{Float64})
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    print(io, "float_lin_eq($(coefficients), [$(_fzn_f(model, variables))], $(value))")
end

# TODO: float_lin_eq_reif

function write_constraint(io::IO, model::Optimizer, f::MOI.ScalarAffineFunction, s::MOI.LessThan{Float64})
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    print(io, "float_lin_le($(coefficients), [$(_fzn_f(model, variables))], $(value))")
end

# TODO: float_lin_le_reif

function write_constraint(io::IO, model::Optimizer, f::MOI.ScalarAffineFunction, s::CP.Strictly{MOI.LessThan{Float64}})
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    print(io, "float_lin_lt($(coefficients), [$(_fzn_f(model, variables))], $(value))")
end

# TODO: float_lin_lt_reif

function write_constraint(io::IO, model::Optimizer, f::MOI.ScalarAffineFunction, s::CP.DifferentFrom{Float64})
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    print(io, "float_lin_ne($(coefficients), [$(_fzn_f(model, variables))], $(value))")
end

# TODO: float_lin_ne_reif
# TODO: float_ln, float_log10, float_log2

# float_lt, float_lt_reif: meaningless for MOI, no way to represent "x < y"
# natively (goes through affine expressions).

# TODO: float_max (CP equivalent!?)
# TODO: float_min (CP equivalent!?)

# float_net, float_ne_reif: meaningless for MOI, no way to represent "x != y"
# natively (goes through affine expressions).

# TODO: float_pow, float_sin, float_sinh, float_sqrt, float_tan, float_tanh, float_times
# TODO: int2float, not in CP for now.

# Objective printing.

function write_objective(io::IO, model::Optimizer)
    print(io, "solve ")
    if model.objective_sense == MOI.FEASIBILITY_SENSE && model.objective_function === nothing
        print(io, "satisfy")
    elseif model.objective_sense == MOI.MIN_SENSE && model.objective_function !== nothing
        print(io, "minimize $(_fzn_f(model, model.objective_function))")
        write_function(io, model, model.objective_function)
    elseif model.objective_sense == MOI.MAX_SENSE && model.objective_function !== nothing
        print(io, "maximize $(_fzn_f(model, model.objective_function))")
    else
        error("Assertion failed when printing the objective. Sense: $(model.objective_sense). Function: $(model.objective_function).")
    end
    print(io, ";")
    println(io)
end

# Function printing.

_fzn_f(model::Optimizer, f::MOI.SingleVariable) = _fzn_f(model, f.variable)
_fzn_f(model::Optimizer, f::MOI.VariableIndex) = model.variable_info[f].name
_fzn_f(model::Optimizer, fs::Vector{MOI.VariableIndex}) = join([_fzn_f(model, f) for f in fs], ", ")

# Destructuring.

function _saf_to_coef_vars(f::MOI.ScalarAffineFunction)
    MOIU.canonicalize!(f)
    variables = MOI.VariableIndex[t.variable_index for t in f.terms]
    coefficients = Int[t.coefficient for t in f.terms]

    return variables, coefficients
end

# =============================================================================
# =
# = Import from the FlatZinc format.
# =
# =============================================================================

function Base.read!(::IO, ::Optimizer)
    return error("read! is not implemented for FlatZinc (fzn) files.")
end

end