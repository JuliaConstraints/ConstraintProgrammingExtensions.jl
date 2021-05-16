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
    set::MOI.AbstractSet
end

mutable struct ConstraintInfo
    index::MOI.ConstraintIndex
    # FlatZinc does not allow constraint names.
    f::MOI.AbstractFunction
    s::MOI.AbstractSet
    output_as_part_of_variable::Bool
end

mutable struct Optimizer <: MOI.AbstractOptimizer
    # A mapping from the MOI.VariableIndex to the variable object.
    # VariableInfo also stores some additional fields like the type of variable.
    variable_info::CleverDicts.CleverDict{MOI.VariableIndex, VariableInfo}

    # A mapping from the MOI.ConstraintIndex to the variable object.
    # ConstraintInfo also stores some additional fields like the type of 
    # constraint. Deletion of constraints is not supported (having a vector 
    # ensures that the order in which constraints are added is respected when 
    # outputting the model, which makes testing easier).
    constraint_info::Vector{ConstraintInfo}

    # Memorise the objective sense and the function separately.
    # The function can only be a single variable, as per FlatZinc limitations.
    objective_sense::MOI.OptimizationSense
    objective_function::Union{Nothing, MOI.SingleVariable}

    """
        Optimizer()

    Create a new Optimizer object.
    """
    function Optimizer()
        model = new()
        model.variable_info =
            CleverDicts.CleverDict{MOI.VariableIndex, VariableInfo}()
        model.constraint_info = ConstraintInfo[]

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

function MOI.set(
    model::Optimizer,
    ::MOI.ObjectiveFunction{MOI.SingleVariable},
    f::MOI.SingleVariable,
)
    return model.objective_function = f
end

function MOI.set(
    model::Optimizer,
    ::MOI.ObjectiveSense,
    s::MOI.OptimizationSense,
)
    return model.objective_sense = s
end

function _create_variable(
    model::Optimizer,
    set::Union{MOI.AbstractScalarSet, MOI.Reals},
)
    index = CleverDicts.add_item(
        model.variable_info,
        VariableInfo(MOI.VariableIndex(0), "", set),
    )
    model.variable_info[index].index = index
    return index
end

function _create_constraint(
    model::Optimizer,
    f::F,
    set::S,
    as_part_of_variable::Bool,
) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    index = MOI.ConstraintIndex{F, S}(length(model.constraint_info) + 1)
    push!(
        model.constraint_info,
        ConstraintInfo(index, f, set, as_part_of_variable),
    )
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

function MOI.supports_add_constrained_variables(
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

function MOI.add_variable(model::Optimizer)
    return _create_variable(model, MOI.Reals(1))
end

function MOI.add_constrained_variables(
    model::Optimizer,
    sets::AbstractVector{<:MOI.AbstractScalarSet},
)
    # TODO: memorise that these variables are part of the same call, so that 
    # the generated FlatZinc is shorter (array of variables)? This would 
    # require that all sets are identical, though.
    vidx = [_create_variable(model, sets[i]) for i in 1:length(sets)]
    cidx = [
        _create_constraint(model, MOI.SingleVariable(vidx[i]), sets[i], true) for i in 1:length(sets)
    ]
    return vidx, cidx
end

function MOI.add_constrained_variable(
    model::Optimizer,
    set::MOI.AbstractScalarSet,
)
    vidx = _create_variable(model, set)
    cidx = _create_constraint(model, MOI.SingleVariable(vidx), set, true)
    return vidx, cidx
end

function MOI.is_valid(model::Optimizer, v::MOI.VariableIndex)
    return haskey(model.variable_info, v)
end

function MOI.get(model::Optimizer, ::MOI.ListOfVariableIndices)
    return collect(keys(model.variable_info))
end

# Constraints.

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{F, S},
) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    info = get(model.constraint_info, c.value, nothing)
    return info !== nothing && typeof(info.s) == S
end

function MOI.add_constraint(
    model::Optimizer,
    f::F,
    s::S,
) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    index = MOI.ConstraintIndex{F, S}(length(model.constraint_info) + 1)
    push!(model.constraint_info, ConstraintInfo(index, f, s, false))
    return index
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{F, S},
) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    return model.constraint_info[c.value].f
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{F, S},
) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    return model.constraint_info[c.value].s
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.SingleVariable},
    ::Type{MOI.LessThan{Int}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.SingleVariable},
    ::Type{MOI.LessThan{Float64}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.SingleVariable},
    ::Type{CP.Strictly{MOI.LessThan{Float64}}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.SingleVariable},
    ::Type{CP.Domain{Int}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.SingleVariable},
    ::Type{MOI.Interval{Float64}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{CP.Element{Int}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{CP.Element{Bool}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{CP.Element{Float64}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{CP.MaximumAmong},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{CP.MinimumAmong},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Int}},
    ::Type{MOI.EqualTo{Int}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Int}},
    ::Type{MOI.LessThan{Int}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Int}},
    ::Type{CP.DifferentFrom{Int}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Float64}},
    ::Type{MOI.EqualTo{Float64}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Float64}},
    ::Type{MOI.LessThan{Float64}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Float64}},
    ::Type{CP.Strictly{MOI.LessThan{Float64}}},
)
    return true
end
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Float64}},
    ::Type{CP.DifferentFrom{Float64}},
)
    return true
end

function MOI.get(
    model::Optimizer,
    ::MOI.ListOfConstraintIndices{F, S},
) where {F, S}
    return [
        c.index for
        c in model.constraint_info if typeof(c.f) == F && typeof(c.s) == S
    ]
end

function MOI.get(model::Optimizer, ::MOI.ListOfConstraints)
    types = Set{Tuple{Any, Any}}()
    for info in model.constraint_info
        push!(types, (typeof(info.f), typeof(info.s)))
    end
    return collect(types)
end

# =============================================================================
# =
# = Export to the FlatZinc format.
# =
# =============================================================================

const START_REG = r"^[^a-zA-Z]"
const NAME_REG = r"[^A-Za-z0-9_]"

"""
    Base.write(io::IO, model::FlatZinc.Optimizer)

Write `model` to `io` in the FlatZinc (fzn) file format.
"""
function Base.write(io::IO, model::Optimizer)
    MOI.FileFormats.create_unique_variable_names(
        model,
        false,
        [
            s -> match(START_REG, s) !== nothing ? "x" * s : s,
            s -> replace(s, NAME_REG => "_"),
        ],
    )

    write_variables(io, model)
    write_constraints(io, model)
    write_objective(io, model)

    return
end

function write_variables(io::IO, model::Optimizer)
    for var in values(model.variable_info)
        # Variables either start with "var" or "array of var", let 
        # write_variable decide.
        write_variable(io, var.name, var.set)
        println(io)
    end
    return println(io)
end

function write_constraints(io::IO, model::Optimizer)
    for cons in model.constraint_info
        if !cons.output_as_part_of_variable
            print(io, "constraint ")
            write_constraint(io, model, cons.f, cons.s)
            print(io, ";")
            println(io)
        end
    end
    return println(io)
end

# Variable printing.

function write_variable(io::IO, name::String, s::MOI.EqualTo{Float64})
    return print(io, "var float: $(name) = $(s.value);")
end

function write_variable(io::IO, name::String, s::MOI.EqualTo{Int})
    return print(io, "var int: $(name) = $(s.value);")
end

function write_variable(io::IO, name::String, s::MOI.EqualTo{Bool})
    return print(io, "var bool: $(name) = $(s.value);")
end

function write_variable(io::IO, name::String, s::MOI.LessThan{Float64})
    # typemin(Float64) is -Inf, which is "-Inf" as a string. Take the next 
    # smallest value as a proxy, because it has a standard scientific notation.
    return print(io, "var $(nextfloat(typemin(Float64)))..$(s.upper): $(name);")
end

function write_variable(io::IO, name::String, s::MOI.LessThan{Int})
    return print(io, "var $(typemin(Int))..$(s.upper): $(name);")
end

function write_variable(io::IO, name::String, s::MOI.GreaterThan{Float64})
    # typemax(Float64) is Inf, which is "Inf" as a string. Take the next 
    # largest value as a proxy, because it has a standard scientific notation.
    return print(io, "var $(s.lower)..$(prevfloat(typemax(Float64))): $(name);")
end

function write_variable(io::IO, name::String, s::MOI.GreaterThan{Int})
    return print(io, "var $(s.lower)..$(typemax(Int)): $(name);")
end

function write_variable(
    io::IO,
    name::String,
    s::MOI.Interval{T},
) where {T <: Union{Int, Float64}}
    return print(io, "var $(s.lower)..$(s.upper): $(name);")
end

function write_variable(io::IO, name::String, ::MOI.Reals)
    return print(io, "var float: $(name);")
end

function write_variable(io::IO, name::String, ::MOI.ZeroOne)
    return print(io, "var bool: $(name);")
end

function write_variable(io::IO, name::String, ::MOI.Integer)
    return print(io, "var bool: $(name);")
end

# Constraint printing.
# Based on the built-in predicates: https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html
# In the same order as the documentation.

# - Integer constraints.

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.VectorOfVariables,
    s::CP.Element{Int},
)
    @assert MOI.output_dimension(f) == 2
    @assert is_integer(model, f.variables[1])
    @assert is_integer(model, f.variables[2])

    value = f.variables[1]
    index = f.variables[2]
    return print(
        io,
        "array_int_element($(_fzn_f(model, index)), $(s.values), $(_fzn_f(model, value)))",
    )
end

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.VectorOfVariables,
    ::CP.MaximumAmong,
)
    for i in 1:MOI.output_dimension(f)
        @assert is_integer(model, f.variables[i])
    end

    array = f.variables[2:end]
    value = f.variables[1]
    return print(
        io,
        "array_int_maximum($(_fzn_f(model, value)), $(_fzn_f(model, array)))",
    )
end

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.VectorOfVariables,
    ::CP.MinimumAmong,
)
    for i in 1:MOI.output_dimension(f)
        @assert is_integer(model, f.variables[i])
    end

    array = f.variables[2:end]
    value = f.variables[1]
    return print(
        io,
        "array_int_minimum($(_fzn_f(model, value)), $(_fzn_f(model, array)))",
    )
end

# TODO: absolute value. int_abs.
# TODO: integer division. int_div

# int_eq, int_eq_reif: meaningless for MOI, no way to represent "x == y" 
# natively (goes through affine expressions).

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.SingleVariable,
    s::MOI.LessThan{Int},
)
    @assert is_integer(model, f)
    return print(io, "int_le($(_fzn_f(model, f)), $(s.upper))")
end

# TODO: int_le_reif

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.ScalarAffineFunction,
    s::MOI.EqualTo{Int},
)
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    return print(
        io,
        "int_lin_eq($(coefficients), [$(_fzn_f(model, variables))], $(value))",
    )
end

# TODO: int_lin_eq_reif

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.ScalarAffineFunction,
    s::MOI.LessThan{Int},
)
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.upper - f.constant
    return print(
        io,
        "int_lin_le($(coefficients), [$(_fzn_f(model, variables))], $(value))",
    )
end

# TODO: int_lin_le_reif

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.ScalarAffineFunction,
    s::CP.DifferentFrom{Int},
)
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    return print(
        io,
        "int_lin_ne($(coefficients), [$(_fzn_f(model, variables))], $(value))",
    )
end

# TODO: int_lin_ne_reif

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.SingleVariable,
    s::CP.Strictly{MOI.LessThan{Int}},
)
    @assert is_integer(model, f)
    return print(io, "int_lt($(_fzn_f(model, f)), $(s.set.upper))")
end

# TODO: int_lt_reif
# TODO: int_max (CP equivalent!?)
# TODO: int_min (CP equivalent!?)
# TODO: int_mod, modulo

# int_ne, int_ne_reif: meaningless for MOI, no way to represent "x == y"
# natively (goes through affine expressions).

# TODO: int_pow.
# TODO: int_times.

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.SingleVariable,
    s::CP.Domain{Int},
)
    @assert is_integer(model, f)
    return print(io, "set_in($(_fzn_f(model, f)), $(s.values))")
end

# - Boolean constraints.

# TODO: array_bool_and, no conjunction between variables for now in CP.

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.VectorOfVariables,
    s::CP.Element{Bool},
)
    @assert MOI.output_dimension(f) == 2
    @assert is_binary(model, f.variables[1])
    @assert is_binary(model, f.variables[2])

    value = f.variables[1]
    index = f.variables[2]

    # Standard interpolation of a vector of boolean will show the type, which is not wanted.
    values = join([ifelse(v, "1", "0") for v in s.values], ", ")

    return print(
        io,
        "array_bool_element($(_fzn_f(model, index)), [$(values)], $(_fzn_f(model, value)))",
    )
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

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.VectorOfVariables,
    s::CP.Element{Float64},
)
    @assert MOI.output_dimension(f) == 2
    value = f.variables[1]
    index = f.variables[2]
    return print(
        io,
        "array_float_element($(_fzn_f(model, index)), $(s.values), $(_fzn_f(model, value)))",
    )
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

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.SingleVariable,
    s::MOI.Interval{Float64},
)
    return print(io, "float_in($(_fzn_f(model, f)), $(s.lower), $(s.upper))")
end

# TODO: float_in_reif

# float_le, float_le_reif: meaningless for MOI, no way to represent "x <= y"
# natively (goes through affine expressions).

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.ScalarAffineFunction,
    s::MOI.EqualTo{Float64},
)
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    return print(
        io,
        "float_lin_eq($(coefficients), [$(_fzn_f(model, variables))], $(value))",
    )
end

# TODO: float_lin_eq_reif

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.ScalarAffineFunction,
    s::MOI.LessThan{Float64},
)
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.upper - f.constant
    return print(
        io,
        "float_lin_le($(coefficients), [$(_fzn_f(model, variables))], $(value))",
    )
end

# TODO: float_lin_le_reif

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.ScalarAffineFunction,
    s::CP.Strictly{MOI.LessThan{Float64}},
)
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.set.upper - f.constant
    return print(
        io,
        "float_lin_lt($(coefficients), [$(_fzn_f(model, variables))], $(value))",
    )
end

# TODO: float_lin_lt_reif

function write_constraint(
    io::IO,
    model::Optimizer,
    f::MOI.ScalarAffineFunction,
    s::CP.DifferentFrom{Float64},
)
    variables, coefficients = _saf_to_coef_vars(f)
    value = s.value - f.constant
    return print(
        io,
        "float_lin_ne($(coefficients), [$(_fzn_f(model, variables))], $(value))",
    )
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

# - MiniZinc 2.0.0
# TODO: bool_clause_reif.

# - MiniZinc 2.0.2
# TODO: array_var_bool_element_nonshifted, array_var_float_element_nonshifted, 
# array_var_int_element_nonshifted, array_var_set_element_nonshifted

# - MiniZinc 2.1.0
# Already included above, like in the docs.

# - MiniZinc 2.2.1
# TODO: int_pow_fixed

# - MiniZinc 2.3.3
# TODO: float_set_in

# - MiniZinc 2.5.2
# TODO: array_var_bool_element2d_nonshifted, array_var_float_element2d_nonshifted, 
# array_var_int_element2d_nonshifted, array_var_set_element2d_nonshifted

# Objective printing.

function write_objective(io::IO, model::Optimizer)
    print(io, "solve ")
    if model.objective_sense == MOI.FEASIBILITY_SENSE &&
       model.objective_function === nothing
        print(io, "satisfy")
    elseif model.objective_sense == MOI.MIN_SENSE &&
           model.objective_function !== nothing
        print(io, "minimize $(_fzn_f(model, model.objective_function))")
    elseif model.objective_sense == MOI.MAX_SENSE &&
           model.objective_function !== nothing
        print(io, "maximize $(_fzn_f(model, model.objective_function))")
    else
        error(
            "Assertion failed when printing the objective. Sense: $(model.objective_sense). Function: $(model.objective_function).",
        )
    end
    print(io, ";")
    return println(io)
end

# Function printing.

_fzn_f(model::Optimizer, f::MOI.SingleVariable) = _fzn_f(model, f.variable)
_fzn_f(model::Optimizer, f::MOI.VariableIndex) = model.variable_info[f].name
function _fzn_f(model::Optimizer, fs::Vector{MOI.VariableIndex})
    return join([_fzn_f(model, f) for f in fs], ", ")
end

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
