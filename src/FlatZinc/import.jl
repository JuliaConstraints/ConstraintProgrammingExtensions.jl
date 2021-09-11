# =============================================================================
# =
# = Import from the FlatZinc format.
# =
# =============================================================================

@enum FznParserstate FznPredicate FznParameter FznVar FznConstraint FznSolve FznDone
@enum FznVariableType FznBool FznInt FznFloat
@enum FznVariableValueMultiplicity FznScalar FznSet
@enum FznObjective FznSatisfy FznMinimise FznMaximise
@enum FznConstraintIdentifier begin
    # To be kept consistent with parse_constraint_verb. 

    # Integers. 
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#integer-flatzinc-builtins
    FznArrayIntElement
    FznArrayIntMaximum
    FznArrayIntMinimum
    FznArrayVarIntElement
    FznIntAbs
    FznIntDiv
    FznIntEq
    FznIntEqReif
    FznIntLe
    FznIntLeReif
    FznIntLinEq
    FznIntLinEqReif
    FznIntLinLe
    FznIntLinLeReif
    FznIntLinNe
    FznIntLinNeReif
    FznIntLt
    FznIntLtReif
    FznIntMax
    FznIntMin
    FznIntMod
    FznIntNe
    FznIntNeReif
    FznIntPlus
    FznIntPow
    FznIntTimes
    # FznSetIn # Defined within sets.
    # Booleans. 
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#bool-flatzinc-builtins
    FznArrayBoolAnd
    FznArrayBoolElement
    FznArrayBoolOr
    FznArrayBoolXor
    FznArrayVarBoolElement
    FznBoolToInt
    FznBoolAnd
    FznBoolClause # Reif below.
    FznBoolEq
    FznBoolEqReif
    FznBoolLe
    FznBoolLeReif
    FznBoolLinEq # No _reif.
    FznBoolLinLe # No _reif.
    FznBoolLt
    FznBoolLtReif
    FznBoolNot
    FznBoolOr
    FznBoolXor # No _reif, even though the doc seems to imply its existence.
    # Sets.
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#set-flatzinc-builtins
    FznArraySetElement
    FznArrayVarSetElement
    FznSetCard
    FznSetDiff
    FznSetEq
    FznSetEqReif
    FznSetIn
    FznSetInReif
    FznSetIntersect
    FznSetLe
    FznSetLeReif
    FznSetLt
    FznSetLtReif
    FznSetNe
    FznSetNeReif
    FznSetSubset
    FznSetSubsetReif
    FznSetSuperset
    FznSetSupersetReif
    FznSetSymdiff
    FznSetUnion
    # Floats.
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#float-flatzinc-builtins
    FznArrayFloatElement
    FznArrayFloatMaximum
    FznArrayFloatMinimum
    FznArrayVarFloatElement
    FznFloatAbs
    FznFloatAcos
    FznFloatAcosh
    FznFloatAsin
    FznFloatAsinh
    FznFloatAtan
    FznFloatAtanh
    FznFloatCos
    FznFloatCosh
    FznFloatDiv
    FznFloatDom
    FznFloatEq
    FznFloatEqReif
    FznFloatExp
    FznFloatIn
    FznFloatInReif
    FznFloatLe
    FznFloatLeReif
    FznFloatLinEq
    FznFloatLinEqReif
    FznFloatLinLe
    FznFloatLinLeReif
    FznFloatLinLt
    FznFloatLinLtReif
    FznFloatLinNe
    FznFloatLinNeReif
    FznFloatLn
    FznFloatLog10
    FznFloatLog2
    FznFloatLt
    FznFloatLtReif
    FznFloatMax
    FznFloatMin
    FznFloatNe
    FznFloatNeReif
    FznFloatPlus
    FznFloatPow
    FznFloatSin
    FznFloatSinh
    FznFloatSqrt
    FznFloatTan
    FznFloatTanh
    FznFloatTimes
    FznIntToFloat
    # New in MiniZinc 2.0.0. Most of them are already included above.
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-0-0
    FznBoolClauseReif
    # New in MiniZinc 2.0.2.
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-0-2
    FznArrayVarBoolElementNonshifted
    FznArrayVarFloatElementNonshifted
    FznArrayVarIntElementNonshifted
    FznArrayVarSetElementNonshifted
    # New in MiniZinc 2.1.0. All of them are already included above.
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-1-0
    # New in MiniZinc 2.1.1. Unimplementable here.
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-1-1
    # New in MiniZinc 2.2.1. 
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-2-1
    FznIntPowFixed
    # New in MiniZinc 2.3.3. 
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-3-3
    FznFloatSetInt
    # New in MiniZinc 2.5.2. 
    # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-5-2
    FznArrayVarBoolElement2DNonshifted
    FznArrayVarFloatElement2DNonshifted
    FznArrayVarIntElement2DNonshifted
    FznArrayVarSetElement2DNonshifted
end

const FZN_UNPARSED_ARGUMENT = Union{AbstractString, Vector{AbstractString}}
const FZN_UNPARSED_ARGUMENT_LIST = Vector{FZN_UNPARSED_ARGUMENT}

const FZN_PARAMETER_TYPES_PREFIX =
    String["bool", "int", "float", "set of int", "array"]

function Base.read!(io::IO, model::Model)
    if !MOI.is_empty(model)
        error("Cannot read in file because model is not empty.")
    end

    # Start parsing loop.
    state = FznPredicate
    while !eof(io)
        # Consistency check: in FznDone state, nothing else can be read.
        if state == FznDone
            break
        end

        # Read an item from the file.
        item = get_fzn_item(io)

        # When get_fzn_item returns an empty line, it has not found any more 
        # item to parse.
        if isempty(item)
            break
        end

        # Depending on the state, different tokens are expected. Not all 
        # statees must be reached for all files: only FznSolve is mandatory, 
        # according to the grammar.
        if state == FznPredicate
            if startswith(item, "predicate")
                parse_predicate!(item, model)
            else
                state = FznParameter
            end
        end

        if state == FznParameter
            if any(
                startswith(item, par_type) for
                par_type in FZN_PARAMETER_TYPES_PREFIX
            )
                parse_parameter!(item, model)
            else
                state = FznVar
            end
        end

        if state == FznVar
            if startswith(item, "var")
                parse_variable!(item, model)
            else
                state = FznConstraint
            end
        end

        if state == FznConstraint
            if startswith(item, "constraint")
                parse_constraint!(item, model)
            else
                state = FznSolve
            end
        end

        if state == FznSolve
            if startswith(item, "solve")
                parse_solve!(item, model)
                state = FznDone
            else
                error("Syntax error: expected a solve-item.")
            end
        end
    end

    return nothing
end

# -----------------------------------------------------------------------------
# - High-level parsing functions (FlatZinc items).
# -----------------------------------------------------------------------------

function parse_predicate!(::AbstractString, ::Model)
    error("Predicates are not supported.")
    return nothing
end

function parse_parameter!(::AbstractString, ::Model)
    error("Parameters are not supported.")
    return nothing
end

function parse_variable!(item::AbstractString, model::Model)
    # Typical input: "var int: x1;"
    # Complex input: "array [1..5] of var int: x1;"
    # Complex input: "var int: x1 :: some_annotation = some_value;"

    # Split the item into interesting parts. 
    var_array, var_type, var_name, var_annotations, var_value =
        split_variable(item)

    # Parse the parts if need be.
    if var_array == ""
        var_array_length = 1
    else
        var_array_length = parse_array_type(var_array)
    end

    var_type, var_multiplicity, var_min, var_max, var_allowed_values =
        parse_variable_type(var_type)

    if length(var_annotations) > 0
        @warn "Annotations are not supported and are currently ignored."
    end

    # Check for name duplicate early on. This avoids starting to fill the MOI
    # model and then failing for an avoidable reason.
    if var_name in keys(model.name_to_var)
        error("Duplicate variable name: $(var_name).")
    end

    # Map to MOI constructs and add into the model.
    if var_multiplicity != FznScalar
        error("Set variables are not supported.")
    end

    if var_array_length != 1
        error("TODO")
        # Encode the position in the array using 
    end

    # - Create the MOI variable.
    moi_set = map_to_moi(var_type)
    if moi_set === nothing
        moi_var = MOI.add_variable(model)
    else
        moi_var, _ = MOI.add_constrained_variable(model, moi_set)
    end

    # - Set the name of the variable.
    MOI.set(model, MOI.VariableName(), moi_var, var_name)

    # - Ease the retrieval of the variable by name for further use.
    model.name_to_var[var_name] = moi_var

    # - Add a range constraint.
    if var_min !== nothing && var_max !== nothing
        MOI.add_constraint(model, moi_var, MOI.Interval(var_min, var_max))
    end

    # - Add a value constraint.
    if var_allowed_values !== nothing
        MOI.add_constraint(model, moi_var, CP.Domain(Set(var_allowed_values)))
    end

    # - Fix the value.
    # TODO: play with var_value.

    return moi_var
end

function parse_constraint!(item::AbstractString, model::Model)
    cons_verb, cons_args, cons_annotations = split_constraint(item)
    cons_verb = parse_constraint_verb(cons_verb)
    cons_args = split_constraint_arguments(cons_args)
    cons_args = parse_constraint_arguments(cons_args)

    if cons_annotations !== nothing
        @warn "Annotations are not supported and are currently ignored."
    end

    add_constraint_to_model(cons_verb, cons_args, model)

    return nothing
end

function parse_solve!(item::AbstractString, model::Model)
    # Typical input: "solve satisfy;", "solve minimize x1;", "solve maximize x1;
    obj_sense, obj_var = CP.FlatZinc.split_solve(item)

    if obj_var !== nothing
        @assert obj_var in keys(model.name_to_var)
        moi_var = model.name_to_var[obj_var]
    end

    if obj_sense == FznSatisfy
        MOI.set(model, MOI.ObjectiveSense(), MOI.FEASIBILITY_SENSE)
    elseif obj_sense == FznMinimise
        MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
        MOI.set(
            model,
            MOI.ObjectiveFunction{MOI.VariableIndex}(),
            moi_var,
        )
    elseif obj_sense == FznMaximise
        MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
        MOI.set(
            model,
            MOI.ObjectiveFunction{MOI.VariableIndex}(),
            moi_var,
        )
    end

    return nothing
end

# -----------------------------------------------------------------------------
# - Mapping between internal state and MOI sets.
# -----------------------------------------------------------------------------

function map_to_moi(var_type::FznVariableType)
    mapping = Dict(
        FznBool => MOI.ZeroOne(),
        FznInt => MOI.Integer(),
        FznFloat => nothing,
    )
    return mapping[var_type]
end

function mixed_var_int_to_moi_var(v::AbstractString, model::Model)
    return model.name_to_var[v]
end

function mixed_var_int_to_moi_var(v::Integer, model::Model)
    moi_var, _ = MOI.add_constrained_variable(model, MOI.Integer())
    MOI.add_constraint(model, moi_var, MOI.EqualTo(v))
    return moi_var
end

function mixed_var_int_to_moi_var(v::Any, ::Model)
    error("Unexpected literal: $v. Expected a variable or an integer.")
    return nothing
end

function mixed_var_bool_to_moi_var(v::AbstractString, model::Model)
    return model.name_to_var[v]
end

function mixed_var_bool_to_moi_var(v::Bool, model::Model)
    moi_var, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
    MOI.add_constraint(model, moi_var, MOI.EqualTo(v))
    return moi_var
end

function mixed_var_bool_to_moi_var(v::Integer, model::Model)
    moi_var, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
    moi_set = if v == 0
        MOI.EqualTo(false)
    elseif v == 1
        MOI.EqualTo(true)
    else
        error("Unexpected literal: $v. Expected a variable or a Boolean.")
    end
    MOI.add_constraint(model, moi_var, moi_set)
    return moi_var
end

function mixed_var_bool_to_moi_var(v::Any, ::Model)
    error("Unexpected literal: $v. Expected a variable or a Boolean.")
    return nothing
end

function mixed_var_float_to_moi_var(v::AbstractString, model::Model)
    return model.name_to_var[v]
end

function mixed_var_float_to_moi_var(v::Real, model::Model)
    moi_var, _ = MOI.add_constrained_variable(model, MOI.EqualTo(v))
    return moi_var
end

function mixed_var_float_to_moi_var(v::Any, ::Model)
    error("Unexpected literal: $v. Expected a variable or a Boolean.")
    return nothing
end

function array_mixed_var_int_to_moi_var(array::Vector, model::Model)
    return MOI.VariableIndex[mixed_var_int_to_moi_var(v, model) for v in array]
end

function array_mixed_var_bool_to_moi_var(array::Vector, model::Model)
    return MOI.VariableIndex[mixed_var_bool_to_moi_var(v, model) for v in array]
end

function array_mixed_var_float_to_moi_var(array::Vector, model::Model)
    return MOI.VariableIndex[
        mixed_var_float_to_moi_var(v, model) for v in array
    ]
end

function add_constraint_to_model(
    cons::FznConstraintIdentifier,
    args,
    model::Model,
)
    return add_constraint_to_model(Val(cons), args, model)
end

function add_constraint_to_model(
    cons_verb::Union{
        Val{FznArrayIntElement},
        Val{FznArrayBoolElement},
        Val{FznArrayFloatElement},
    },
    args,
    model::Model,
)
    @assert length(args) == 3
    @assert typeof(args[1]) <: AbstractString
    @assert typeof(args[2]) <: Vector
    @assert typeof(args[3]) <: AbstractString

    moi_var_index = model.name_to_var[args[1]]
    moi_var_value = model.name_to_var[args[3]]

    array = if cons_verb == Val(FznArrayIntElement)
        Int.(args[2])
    elseif cons_verb == Val(FznArrayBoolElement)
        collect(Bool.(args[2])) # Need a Vector{T}, not a BitVector!
    elseif cons_verb == Val(FznArrayFloatElement)
        Float64.(args[2])
    end

    return MOI.add_constraint(
        model,
        MOI.VectorOfVariables([moi_var_value, moi_var_index]),
        CP.Element(array),
    )
end

function add_constraint_to_model(
    cons_verb::Union{
        Val{FznArrayIntMaximum},
        Val{FznArrayIntMinimum},
        Val{FznArrayFloatMaximum},
        Val{FznArrayFloatMinimum},
    },
    args,
    model::Model,
)
    @assert length(args) == 2
    @assert typeof(args[1]) <: AbstractString
    @assert typeof(args[2]) <: Vector

    moi_var = model.name_to_var[args[1]]
    moi_var_array =
        if cons_verb == Val(FznArrayIntMaximum) ||
           cons_verb == Val(FznArrayIntMinimum)
            array_mixed_var_int_to_moi_var(args[2], model)
        elseif cons_verb == Val(FznArrayFloatMaximum) ||
               cons_verb == Val(FznArrayFloatMinimum)
            array_mixed_var_float_to_moi_var(args[2], model)
        end

    moi_set =
        if cons_verb == Val(FznArrayIntMaximum) ||
           cons_verb == Val(FznArrayFloatMaximum)
            CP.MaximumAmong(length(args[2]))
        elseif cons_verb == Val(FznArrayIntMinimum) ||
               cons_verb == Val(FznArrayFloatMinimum)
            CP.MinimumAmong(length(args[2]))
        end

    return MOI.add_constraint(
        model,
        MOI.VectorOfVariables([moi_var, moi_var_array...]),
        moi_set,
    )
end

function add_constraint_to_model(
    cons_verb::Union{
        Val{FznArrayVarIntElement},
        Val{FznArrayVarBoolElement},
        Val{FznArrayVarFloatElement},
    },
    args,
    model::Model,
)
    @assert length(args) == 3
    @assert typeof(args[1]) <: AbstractString
    @assert typeof(args[2]) <: Vector
    @assert typeof(args[3]) <: AbstractString

    moi_var_index = model.name_to_var[args[1]]
    moi_var_value = model.name_to_var[args[3]]

    moi_var_array = if cons_verb == Val(FznArrayVarIntElement)
        array_mixed_var_int_to_moi_var(args[2], model)
    elseif cons_verb == Val(FznArrayVarBoolElement)
        array_mixed_var_bool_to_moi_var(args[2], model)
    elseif cons_verb == Val(FznArrayVarFloatElement)
        array_mixed_var_float_to_moi_var(args[2], model)
    end

    return MOI.add_constraint(
        model,
        MOI.VectorOfVariables([moi_var_value, moi_var_index, moi_var_array...]),
        CP.ElementVariableArray(length(args[2])),
    )
end

function add_constraint_to_model(
    cons_verb::Union{
        Val{FznIntEq},
        Val{FznIntLe},
        Val{FznIntLt},
        Val{FznIntNe},
        Val{FznBoolEq},
        Val{FznBoolLe},
        Val{FznBoolLt},
        Val{FznFloatEq},
        Val{FznFloatLe},
        Val{FznFloatLt},
        Val{FznFloatNe},
    },
    args,
    model::Model,
)
    @assert length(args) == 2
    @assert typeof(args[1]) <: AbstractString ||
            typeof(args[2]) <: AbstractString

    moi_lhs = args[1]
    moi_rhs = args[2]

    type =
        if cons_verb == Val(FznIntEq) ||
           cons_verb == Val(FznBoolEq) ||
           cons_verb == Val(FznIntLe) ||
           cons_verb == Val(FznBoolLe) ||
           cons_verb == Val(FznIntLt) ||
           cons_verb == Val(FznBoolLt) ||
           cons_verb == Val(FznIntNe)
            Int
        elseif cons_verb == Val(FznFloatEq) ||
               cons_verb == Val(FznFloatLe) ||
               cons_verb == Val(FznFloatLt) ||
               cons_verb == Val(FznFloatNe)
            Float64
        end

    # Both are variable: encode the constraint "x - y = 0".
    if typeof(moi_lhs) <: AbstractString && typeof(moi_rhs) <: AbstractString
        moi_lhs = model.name_to_var[moi_lhs]
        moi_rhs = model.name_to_var[moi_rhs]

        moi_set =
            if cons_verb == Val(FznIntEq) ||
               cons_verb == Val(FznBoolEq) ||
               cons_verb == Val(FznFloatEq)
                MOI.EqualTo(zero(type))
            elseif cons_verb == Val(FznIntLe) ||
                   cons_verb == Val(FznBoolLe) ||
                   cons_verb == Val(FznFloatLe)
                MOI.LessThan(zero(type))
            elseif cons_verb == Val(FznIntLt) ||
                   cons_verb == Val(FznBoolLt) ||
                   cons_verb == Val(FznFloatLt)
                CP.Strictly(MOI.LessThan(zero(type)))
            elseif cons_verb == Val(FznIntNe) || cons_verb == Val(FznFloatNe)
                CP.DifferentFrom(zero(type))
            end

        return MOI.add_constraint(
            model,
            MOI.ScalarAffineFunction(
                MOI.ScalarAffineTerm.(
                    [one(type), -one(type)],
                    [moi_lhs, moi_rhs],
                ),
                zero(type),
            ),
            moi_set,
        )
    end

    # Only one variable: consider that lhs is a variable.
    lhs_coeff = one(type)
    rhs_coeff = one(type)
    if typeof(moi_rhs) <: AbstractString
        moi_lhs, moi_rhs = moi_rhs, moi_lhs

        # For a <= constraint, reversing the order means that signs must change too.
        if cons_verb == Val(FznIntLe) ||
           cons_verb == Val(FznIntLt) ||
           cons_verb == Val(FznBoolLe) ||
           cons_verb == Val(FznBoolLt) ||
           cons_verb == Val(FznFloatLe) ||
           cons_verb == Val(FznFloatLt)
            lhs_coeff = -one(type)
            rhs_coeff = -one(type)
        end
    end

    moi_lhs = model.name_to_var[moi_lhs]

    moi_set =
        if cons_verb == Val(FznIntEq) ||
           cons_verb == Val(FznBoolEq) ||
           cons_verb == Val(FznFloatEq)
            MOI.EqualTo(rhs_coeff * moi_rhs)
        elseif cons_verb == Val(FznIntLe) ||
               cons_verb == Val(FznBoolLe) ||
               cons_verb == Val(FznFloatLe)
            MOI.LessThan(rhs_coeff * moi_rhs)
        elseif cons_verb == Val(FznIntLt) ||
               cons_verb == Val(FznBoolLt) ||
               cons_verb == Val(FznFloatLt)
            CP.Strictly(MOI.LessThan(rhs_coeff * moi_rhs))
        elseif cons_verb == Val(FznIntNe) || cons_verb == Val(FznFloatNe)
            CP.DifferentFrom(rhs_coeff * moi_rhs)
        end

    return MOI.add_constraint(
        model,
        MOI.ScalarAffineFunction(
            [MOI.ScalarAffineTerm(lhs_coeff, moi_lhs)],
            zero(type),
        ),
        moi_set,
    )
end

function add_constraint_to_model(
    cons_verb::Union{
        Val{FznIntEqReif},
        Val{FznIntLeReif},
        Val{FznIntLtReif},
        Val{FznIntNeReif},
        Val{FznBoolEqReif},
        Val{FznBoolLeReif},
        Val{FznBoolLtReif},
        Val{FznFloatEqReif},
        Val{FznFloatLeReif},
        Val{FznFloatLtReif},
        Val{FznFloatNeReif},
    },
    args,
    model::Model,
)
    @assert length(args) == 3
    @assert typeof(args[1]) <: AbstractString ||
            typeof(args[2]) <: AbstractString
    @assert typeof(args[3]) <: AbstractString

    moi_lhs = args[1]
    moi_rhs = args[2]
    moi_reif = model.name_to_var[args[3]]

    type =
        if cons_verb == Val(FznIntEqReif) ||
           cons_verb == Val(FznBoolEqReif) ||
           cons_verb == Val(FznIntLeReif) ||
           cons_verb == Val(FznBoolLeReif) ||
           cons_verb == Val(FznIntLtReif) ||
           cons_verb == Val(FznBoolLtReif) ||
           cons_verb == Val(FznIntNeReif)
            Int
        elseif cons_verb == Val(FznFloatEqReif) ||
               cons_verb == Val(FznFloatLeReif) ||
               cons_verb == Val(FznFloatLtReif) ||
               cons_verb == Val(FznFloatNeReif)
            Float64
        end

    # Both are variable: encode the constraint "z <=> (x - y = 0)".
    if typeof(moi_lhs) <: AbstractString && typeof(moi_rhs) <: AbstractString
        moi_lhs = model.name_to_var[moi_lhs]
        moi_rhs = model.name_to_var[moi_rhs]

        moi_set =
            if cons_verb == Val(FznIntEqReif) ||
               cons_verb == Val(FznBoolEqReif) ||
               cons_verb == Val(FznFloatEqReif)
                CP.Reification(MOI.EqualTo(zero(type)))
            elseif cons_verb == Val(FznIntLeReif) ||
                   cons_verb == Val(FznBoolLeReif) ||
                   cons_verb == Val(FznFloatLeReif)
                CP.Reification(MOI.LessThan(zero(type)))
            elseif cons_verb == Val(FznIntLtReif) ||
                   cons_verb == Val(FznBoolLtReif) ||
                   cons_verb == Val(FznFloatLtReif)
                CP.Reification(CP.Strictly(MOI.LessThan(zero(type))))
            elseif cons_verb == Val(FznIntNeReif) ||
                   cons_verb == Val(FznFloatNeReif)
                CP.Reification(CP.DifferentFrom(zero(type)))
            end

        return MOI.add_constraint(
            model,
            MOI.VectorAffineFunction(
                [
                    MOI.VectorAffineTerm(
                        1,
                        MOI.ScalarAffineTerm(one(type), moi_reif),
                    ),
                    MOI.VectorAffineTerm(
                        2,
                        MOI.ScalarAffineTerm(one(type), moi_lhs),
                    ),
                    MOI.VectorAffineTerm(
                        2,
                        MOI.ScalarAffineTerm(-one(type), moi_rhs),
                    ),
                ],
                [zero(type), zero(type)],
            ),
            moi_set,
        )
    end

    # Only one variable: consider that lhs is a variable.
    lhs_coeff = one(type)
    rhs_coeff = one(type)
    if typeof(moi_rhs) <: AbstractString
        moi_lhs, moi_rhs = moi_rhs, moi_lhs

        # For a <= constraint, reversing the order means that signs must change too.
        if cons_verb == Val(FznIntLeReif) ||
           cons_verb == Val(FznIntLtReif) ||
           cons_verb == Val(FznBoolLeReif) ||
           cons_verb == Val(FznBoolLtReif) ||
           cons_verb == Val(FznFloatLeReif) ||
           cons_verb == Val(FznFloatLtReif)
            lhs_coeff = -one(type)
            rhs_coeff = -one(type)
        end
    end

    moi_lhs = model.name_to_var[moi_lhs]

    moi_set =
        if cons_verb == Val(FznIntEqReif) ||
           cons_verb == Val(FznBoolEqReif) ||
           cons_verb == Val(FznFloatEqReif)
            CP.Reification(MOI.EqualTo(rhs_coeff * moi_rhs))
        elseif cons_verb == Val(FznIntLeReif) ||
               cons_verb == Val(FznBoolLeReif) ||
               cons_verb == Val(FznFloatLeReif)
            CP.Reification(MOI.LessThan(rhs_coeff * moi_rhs))
        elseif cons_verb == Val(FznIntLtReif) ||
               cons_verb == Val(FznBoolLtReif) ||
               cons_verb == Val(FznFloatLtReif)
            CP.Reification(CP.Strictly(MOI.LessThan(rhs_coeff * moi_rhs)))
        elseif cons_verb == Val(FznIntNeReif) ||
               cons_verb == Val(FznFloatNeReif)
            CP.Reification(CP.DifferentFrom(rhs_coeff * moi_rhs))
        end

    return MOI.add_constraint(
        model,
        MOI.VectorAffineFunction(
            [
                MOI.VectorAffineTerm(
                    1,
                    MOI.ScalarAffineTerm(one(type), moi_reif),
                ),
                MOI.VectorAffineTerm(
                    2,
                    MOI.ScalarAffineTerm(lhs_coeff, moi_lhs),
                ),
            ],
            [zero(type), zero(type)],
        ),
        moi_set,
    )
end

# FznIntAbs: not supported yet.
# FznIntDiv: not supported yet.
# FznIntLe: implemented within FznIntEq.
# FznIntLeReif: implemented within FznIntEqReif.

function add_constraint_to_model(
    cons_verb::Union{
        Val{FznIntLinEq},
        Val{FznIntLinLe},
        Val{FznIntLinNe},
        Val{FznBoolLinEq},
        Val{FznBoolLinLe},
        Val{FznFloatLinEq},
        Val{FznFloatLinLe},
        Val{FznFloatLinLt},
        Val{FznFloatLinNe},
        Val{FznIntLinEqReif},
        Val{FznIntLinLeReif},
        Val{FznIntLinNeReif},
        Val{FznFloatLinEqReif},
        Val{FznFloatLinLeReif},
        Val{FznFloatLinLtReif},
        Val{FznFloatLinNeReif},
    },
    args,
    model::Model,
)
    if cons_verb ∈ [
        Val(FznIntLinEq),
        Val(FznIntLinLe),
        Val(FznIntLinNe),
        Val(FznBoolLinEq),
        Val(FznBoolLinLe),
        Val(FznFloatLinEq),
        Val(FznFloatLinLe),
        Val(FznFloatLinLt),
        Val(FznFloatLinNe),
    ]
        @assert length(args) == 3
    elseif cons_verb ∈ [
        Val(FznIntLinEqReif),
        Val(FznIntLinLeReif),
        Val(FznIntLinNeReif),
        Val(FznFloatLinEqReif),
        Val(FznFloatLinLeReif),
        Val(FznFloatLinLtReif),
        Val(FznFloatLinNeReif),
    ]
        @assert length(args) == 4
    else
        @assert false
    end

    @assert typeof(args[1]) <: Vector
    @assert typeof(args[2]) <: Vector

    if cons_verb ∈ [
        Val(FznIntLinEq),
        Val(FznIntLinLe),
        Val(FznIntLinNe),
        Val(FznBoolLinEq),
        Val(FznBoolLinLe),
        Val(FznIntLinEqReif),
        Val(FznIntLinLeReif),
        Val(FznIntLinNeReif),
    ]
        @assert typeof(args[3]) <: Integer
    else
        @assert typeof(args[3]) <: Real
    end
    if cons_verb ∈ [
        Val(FznIntLinEqReif),
        Val(FznIntLinLeReif),
        Val(FznIntLinNeReif),
        Val(FznFloatLinEqReif),
        Val(FznFloatLinLeReif),
        Val(FznFloatLinLtReif),
        Val(FznFloatLinNeReif),
    ]
        @assert typeof(args[4]) <: AbstractString
    end

    @assert length(args[1]) == length(args[2])

    # Create the linear combination.
    type =
        if cons_verb ∈ [
            Val(FznIntLinEq),
            Val(FznIntLinLe),
            Val(FznIntLinNe),
            Val(FznBoolLinEq),
            Val(FznBoolLinLe),
            Val(FznIntLinEqReif),
            Val(FznIntLinLeReif),
            Val(FznIntLinNeReif),
        ]
            Int
        else
            Float64
        end

    moi_terms = [
        MOI.ScalarAffineTerm{type}(args[1][i], model.name_to_var[args[2][i]]) for i in 1:length(args[1])
    ]

    # Non-reified constraint.
    if cons_verb ∈ [
        Val(FznIntLinEq),
        Val(FznIntLinLe),
        Val(FznIntLinNe),
        Val(FznBoolLinEq),
        Val(FznBoolLinLe),
        Val(FznFloatLinEq),
        Val(FznFloatLinLe),
        Val(FznFloatLinLt),
        Val(FznFloatLinNe),
    ]
        moi_fct = MOI.ScalarAffineFunction(moi_terms, zero(type))

        cst = type(args[3])
        moi_set =
            if cons_verb == Val(FznIntLinEq) ||
               cons_verb == Val(FznBoolLinEq) ||
               cons_verb == Val(FznFloatLinEq)
                MOI.EqualTo(cst)
            elseif cons_verb == Val(FznIntLinLe) ||
                   cons_verb == Val(FznBoolLinLe) ||
                   cons_verb == Val(FznFloatLinLe)
                MOI.LessThan(cst)
            elseif cons_verb == Val(FznFloatLinLt)
                CP.Strictly(MOI.LessThan(cst))
            elseif cons_verb == Val(FznIntLinNe) ||
                   cons_verb == Val(FznFloatLinNe)
                CP.DifferentFrom(cst)
            end

        return MOI.add_constraint(model, moi_fct, moi_set)
    end

    # Reified constraint
    if cons_verb ∈ [
        Val(FznIntLinEqReif),
        Val(FznIntLinLeReif),
        Val(FznIntLinNeReif),
        Val(FznFloatLinEqReif),
        Val(FznFloatLinLeReif),
        Val(FznFloatLinLtReif),
        Val(FznFloatLinNeReif),
    ]
        moi_fct = MOI.VectorAffineFunction(
            [
                MOI.VectorAffineTerm(
                    1,
                    MOI.ScalarAffineTerm(one(type), model.name_to_var[args[4]]),
                ),
                MOI.VectorAffineTerm.(2, moi_terms)...,
            ],
            [zero(type), zero(type)],
        )

        cst = type(args[3])
        moi_set =
            if cons_verb == Val(FznIntLinEqReif) ||
               cons_verb == Val(FznFloatLinEqReif)
                CP.Reification(MOI.EqualTo(cst))
            elseif cons_verb == Val(FznIntLinLeReif) ||
                   cons_verb == Val(FznFloatLinLeReif)
                CP.Reification(MOI.LessThan(cst))
            elseif cons_verb == Val(FznFloatLinLtReif)
                CP.Reification(CP.Strictly(MOI.LessThan(cst)))
            elseif cons_verb == Val(FznIntLinNeReif) ||
                   cons_verb == Val(FznFloatLinNeReif)
                CP.Reification(CP.DifferentFrom(cst))
            end

        return MOI.add_constraint(model, moi_fct, moi_set)
    end

    @assert false
end

# FznIntLt: implemented within FznIntEq.
# FznIntLtReif: implemented within FznIntEqReif.

function add_constraint_to_model(
    cons_verb::Union{
        Val{FznIntMax},
        Val{FznIntMin},
        Val{FznFloatMax},
        Val{FznFloatMin},
    },
    args,
    model::Model,
)
    @assert length(args) == 3
    for i in 1:3
        @assert typeof(args[i]) <: AbstractString
    end

    moi_var = model.name_to_var[args[3]]
    moi_var_array = [model.name_to_var[args[1]], model.name_to_var[args[2]]]

    moi_set = if cons_verb == Val(FznIntMax) || cons_verb == Val(FznFloatMax)
        CP.MaximumAmong(2)
    elseif cons_verb == Val(FznIntMin) || cons_verb == Val(FznFloatMin)
        CP.MinimumAmong(2)
    end

    return MOI.add_constraint(
        model,
        MOI.VectorOfVariables([moi_var, moi_var_array...]),
        moi_set,
    )
end

# FznIntMod: not supported yet.
# FznIntNe: implemented within FznIntEq.
# FznIntNeReif: implemented within FznIntEqReif.

function add_constraint_to_model(
    cons_verb::Union{Val{FznIntPlus}, Val{FznFloatPlus}},
    args,
    model::Model,
)
    @assert length(args) == 3
    for i in 1:3
        @assert typeof(args[i]) <: AbstractString
    end

    moi_var = model.name_to_var[args[3]]
    moi_operands = [model.name_to_var[args[1]], model.name_to_var[args[2]]]

    type = if cons_verb == Val(FznIntPlus)
        Int
    elseif cons_verb == Val(FznFloatPlus)
        Float64
    end

    return MOI.add_constraint(
        model,
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.(
                [one(type), one(type), -one(type)],
                [moi_operands..., moi_var],
            ),
            zero(type),
        ),
        MOI.EqualTo(zero(type)),
    )
end

# FznIntPow: not supported yet.
# FznIntTimes: not supported yet.
# FznSetIn: not supported yet, missing sets.
# FznArrayBoolAnd: not supported yet.
# FznArrayBoolElement: implemented within FznArrayIntElement.
# FznArrayBoolOr: not supported yet.
# FznArrayBoolXor: not supported yet.
# FznArrayVarBoolElement: implemented within FznArrayVarIntElement.

function add_constraint_to_model(::Val{FznBoolToInt}, args, model::Model)
    @assert length(args) == 2
    for i in 1:2
        @assert typeof(args[i]) <: AbstractString
    end

    moi_var_bool = model.name_to_var[args[1]]
    moi_var_int = model.name_to_var[args[2]]

    return MOI.add_constraint(
        model,
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1, -1], [moi_var_bool, moi_var_int]),
            0,
        ),
        MOI.EqualTo(0),
    )
end

# FznBoolAnd: not supported yet. 
# FznBoolClause: not supported yet.
# FznBoolClauseReif: not supported yet.
# FznBoolEq: implemented within FznIntEq.
# FznBoolEqReif: implemented within FznIntEqReif.
# FznBoolOr: not supported yet.
# FznBoolXor: not supported yet.
# FznBoolLinEq: implemented with FznIntLinEq.
# FznBoolLinLe: implemented with FznIntLinEq.
# FznBoolLt: implemented with FznIntEq.
# FznBoolLtReif: implemented with FznIntEqReif.
# FznBoolNot: not supported yet.
# FznBoolOr: not supported yet.
# FznBoolXor: not supported yet.

# FznArraySetElement: not supported yet, missing sets.
# FznArrayVarSetElement: not supported yet, missing sets.
# FznSetCard: not supported yet, missing sets.
# FznSetDiff: not supported yet, missing sets.
# FznSetEq: not supported yet, missing sets.
# FznSetEqReif: not supported yet, missing sets.
# FznSetIn: not supported yet, missing sets.
# FznSetInReif: not supported yet, missing sets.
# FznSetIntersect: not supported yet, missing sets.
# FznSetLe: not supported yet, missing sets.
# FznSetLeReif: not supported yet, missing sets.
# FznSetLt: not supported yet, missing sets.
# FznSetLtReif: not supported yet, missing sets.
# FznSetNe: not supported yet, missing sets.
# FznSetNeReif: not supported yet, missing sets.
# FznSetSubset: not supported yet, missing sets.
# FznSetSubsetReif: not supported yet, missing sets.
# FznSetSuperset: not supported yet, missing sets.
# FznSetSupersetReif: not supported yet, missing sets.
# FznSetSymdiff: not supported yet, missing sets.
# FznSetUnion: not supported yet, missing sets.

# FznArrayFloatElement: implemented with FznArrayIntElement.
# FznArrayFloatMaximum: implemented with FznArrayIntMaximum.
# FznArrayFloatMinimum: implemented with FznArrayIntMinimum.
# FznArrayVarFloatElement: implemented with FznArrayVarIntElement.
# FznFloatAbs: not supported yet.
# FznFloatAcos: not supported yet.
# FznFloatAcosh: not supported yet.
# FznFloatAsin: not supported yet.
# FznFloatAsinh: not supported yet.
# FznFloatAtan: not supported yet.
# FznFloatAtanh: not supported yet.
# FznFloatCos: not supported yet.
# FznFloatCosh: not supported yet.
# FznFloatDiv: not supported yet.
# FznFloatDom: not supported yet, missing MOI set. Disjunction of several FznFloatIn. 
# (https://github.com/MiniZinc/libminizinc/blob/0848ce7ec78d3051cbe0f9e558af3c9dcfe65606/share/minizinc/std/redefinitions-2.1.mzn)
# FznFloatEq: implemented within FznIntEq.
# FznFloatEqReif: implemented within FznIntEqReif.
# FznFloatExp: not supported yet.

function add_constraint_to_model(::Val{FznFloatIn}, args, model::Model)
    @assert length(args) == 3
    @assert typeof(args[1]) <: AbstractString
    @assert typeof(args[2]) <: Real
    @assert typeof(args[3]) <: Real

    moi_var = model.name_to_var[args[1]]
    bound_min = Float64(args[2])
    bound_max = Float64(args[3])

    return MOI.add_constraint(
        model,
        moi_var,
        MOI.Interval(bound_min, bound_max),
    )
end

function add_constraint_to_model(::Val{FznFloatInReif}, args, model::Model)
    @assert length(args) == 4
    @assert typeof(args[1]) <: AbstractString
    @assert typeof(args[2]) <: Real
    @assert typeof(args[3]) <: Real
    @assert typeof(args[4]) <: AbstractString

    moi_var = model.name_to_var[args[1]]
    bound_min = Float64(args[2])
    bound_max = Float64(args[3])
    moi_bool_var = model.name_to_var[args[4]]

    return MOI.add_constraint(
        model,
        MOI.VectorOfVariables([moi_bool_var, moi_var]),
        CP.Reification(MOI.Interval(bound_min, bound_max)),
    )
end

# FznFloatLe: implemented within FznIntEq.
# FznFloatLeReif: implemented within FznIntEqReif.
# FznFloatLinEq: implemented within FznIntLinEq.
# FznFloatLinEqReif: implemented within FznIntLinEq.
# FznFloatLinLe: implemented within FznIntLinEq.
# FznFloatLinLeReif: implemented within FznIntLinEq.
# FznFloatLinLt: implemented within FznIntLinEq.
# FznFloatLinLtReif: implemented within FznIntLinEq.
# FznFloatLinNe: implemented within FznIntLinEq.
# FznFloatLinNeReif: implemented within FznIntLinEq.
# FznFloatLn: not supported yet.
# FznFloatLog10: not supported yet.
# FznFloatLog2: not supported yet.
# FznFloatLt: implemented within FznIntEq.
# FznFloatLtReif: implemented within FznIntEq.
# FznFloatMax: implemented within FznIntMax.
# FznFloatMin: implemented within FznIntMin.
# FznFloatNe: implemented within FznIntEq.
# FznFloatNeReif: implemented within FznIntEq.
# FznFloatPlus: implemented within FznIntPlus.
# FznFloatPow: not supported yet.
# FznFloatSin: not supported yet.
# FznFloatSinh: not supported yet.
# FznFloatSqrt: not supported yet.
# FznFloatTan: not supported yet.
# FznFloatTanh: not supported yet.
# FznFloatTimes: not supported yet.

# FznBoolClauseReif: not supported yet.

# FznArrayVarBoolElementNonshifted: not supported yet.
# FznArrayVarFloatElementNonshifted: not supported yet.
# FznArrayVarIntElementNonshifted: not supported yet.
# FznArrayVarSetElementNonshifted: not supported yet.

# FznIntPowFixed: not supported yet.
# FznFloatSetInt: not supported yet.

# FznArrayVarBoolElement2DNonshifted: not supported yet.
# FznArrayVarFloatElement2DNonshifted: not supported yet.
# FznArrayVarIntElement2DNonshifted: not supported yet.
# FznArrayVarSetElement2DNonshifted: not supported yet.

function add_constraint_to_model(::Val{FznIntToFloat}, args, model::Model)
    @assert length(args) == 2
    for i in 1:2
        @assert typeof(args[i]) <: AbstractString
    end

    moi_var_int = model.name_to_var[args[1]]
    moi_var_float = model.name_to_var[args[2]]

    return MOI.add_constraint(
        model,
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, -1.0], [moi_var_int, moi_var_float]),
            0.0,
        ),
        MOI.EqualTo(0.0),
    )
end

# -----------------------------------------------------------------------------
# - Low-level parsing functions (other grammar rules), independent of MOI.
# -----------------------------------------------------------------------------

function parse_array_type(var_array::AbstractString)::Union{Nothing, Int}
    # Typical input: "[1..5]"
    # The "1.." part is enforced by the grammar (with the exception of spaces).

    if length(var_array) == 0
        return nothing
    end

    # Get rid of the square brackets.
    @assert var_array[1] == '['
    @assert var_array[end] == ']'
    var_array = string(strip(var_array[2:end-1]))

    # Get rid of the leading "1".
    @assert var_array[1] == '1'
    var_array = string(strip(var_array[2:end]))

    # Get rid of the leading "..".
    @assert var_array[1] == '.'
    @assert var_array[2] == '.'
    var_array = string(strip(var_array[3:end]))

    # What remains should be an integer.
    return parse(Int, var_array)
end

function parse_range(range::AbstractString)
    # Typical inputs: "1..5", "1.5..2.4"
    @assert length(range) > 2

    low, hi = split(range, "..")
    low = strip(low)
    hi = strip(hi)

    # First, try to parse as integers: this is more restrictive than floats.
    try
        low_int = parse(Int, low)
        hi_int = parse(Int, hi)

        return (FznInt, low_int, hi_int)
    catch
        try
            low = parse(Float64, low)
            hi = parse(Float64, hi)

            return (FznFloat, low, hi)
        catch
            error("Ill-formed input: $low, $hi.")
            return nothing
        end
    end
end

function parse_set(set::AbstractString)
    # Typical inputs: "{}", "{1, 2, 3}"
    # Typical inputs: "{}", "{1.0, 2.1, 3.2}"
    @assert length(set) >= 2

    # Get rid of the curly braces
    @assert set[1] == '{'
    @assert set[end] == '}'
    set = set[2:end-1]

    # First, try to parse as integers: this is more restrictive than floats.
    try
        return (FznInt, parse_set_int(set))
    catch
        try
            return (FznFloat, parse_set_float(set))
        catch
            error("Ill-formed input: {$set}.")
            return nothing
        end
    end
end

function parse_set_int(set::AbstractString)
    # Typical inputs: "", "1, 2, 3"

    values = Int[]
    while length(set) > 0
        if occursin(',', set)
            value, set = split(set, ',', limit=2)
            push!(values, parse(Int, value))
        else
            push!(values, parse(Int, set))
            break
        end
    end

    return values
end

function parse_set_float(set::AbstractString)
    # Typical inputs: "", "1.0, 2.1, 3.2"

    values = Float64[]
    while length(set) > 0
        if occursin(',', set)
            value, set = split(set, ',', limit=2)
            push!(values, parse(Float64, value))
        else
            push!(values, parse(Float64, set))
            break
        end
    end

    return values
end

function parse_variable_type(var_type::AbstractString)
    # Typical inputs: "bool", "int", "set of int", "float"
    # Complex inputs: "1..5", "{1, 2, 3}", "1.5..1.7", "set of {1, 2, 3}", "set of 1..2"

    # Return tuple: 
    # - variable type: FznVariableType
    # - variable multiplicity: FznVariableValueMultiplicity
    # - range minimum: Union{Nothing, Int, Float64}
    # - range maximum: Union{Nothing, Int, Float64}
    # - allowed values: Union{Nothing, Vector{Int}, Vector{Float64}}

    # Basic variable type.
    if var_type == "bool"
        return (FznBool, FznScalar, nothing, nothing, nothing)
    elseif var_type == "int"
        return (FznInt, FznScalar, nothing, nothing, nothing)
    elseif var_type == "float"
        return (FznFloat, FznScalar, nothing, nothing, nothing)
    elseif var_type == "set of int"
        return (FznInt, FznSet, nothing, nothing, nothing)
    end

    # Sets, both ranges and sets in extension.
    if startswith(var_type, "set")
        @assert length(var_type) >= 4
        var_type = strip(var_type[4:end])
        @assert startswith(var_type, "of")
        @assert length(var_type) >= 3
        var_type = strip(var_type[3:end])

        if startswith(var_type, '{') && endswith(var_type, '}')
            var_type, var_values = parse_set(var_type)
            return (var_type, FznSet, nothing, nothing, var_values)
        end

        if !startswith(var_type, '{') &&
           !endswith(var_type, '}') &&
           occursin("..", var_type)
            var_type, var_min, var_max = parse_range(var_type)
            return (var_type, FznSet, var_min, var_max, nothing)
        end

        @assert false
    end

    # Ranges, of both integers and floats. Check this as a last step, because 
    # this might conflict with other cases ("set of 1..4", for instance).
    if occursin("..", var_type)
        var_type, var_min, var_max = parse_range(var_type)
        return (var_type, FznScalar, var_min, var_max, nothing)
    end

    # Scalar variables, with sets given in extension.
    if startswith(var_type, '{') && endswith(var_type, '}')
        var_type, var_values = parse_set(var_type)
        return (var_type, FznScalar, nothing, nothing, var_values)
    end

    # If no return previously, this could not be parsed.
    @assert false
end

function parse_constraint_verb(cons_verb::AbstractString)
    # To be kept consistent with FznConstraintIdentifier.
    mapping = Dict(
        # Integers. 
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#integer-flatzinc-builtins
        "array_int_element" => FznArrayIntElement,
        "array_int_maximum" => FznArrayIntMaximum,
        "array_int_minimum" => FznArrayIntMinimum,
        "array_var_int_element" => FznArrayVarIntElement,
        "int_abs" => FznIntAbs,
        "int_div" => FznIntDiv,
        "int_eq" => FznIntEq,
        "int_eq_reif" => FznIntEqReif,
        "int_le" => FznIntLe,
        "int_le_reif" => FznIntLeReif,
        "int_lin_eq" => FznIntLinEq,
        "int_lin_eq_reif" => FznIntLinEqReif,
        "int_lin_le" => FznIntLinLe,
        "int_lin_le_reif" => FznIntLinLeReif,
        "int_lin_ne" => FznIntLinNe,
        "int_lin_ne_reif" => FznIntLinNeReif,
        "int_lt" => FznIntLt,
        "int_lt_reif" => FznIntLtReif,
        "int_max" => FznIntMax,
        "int_min" => FznIntMin,
        "int_mod" => FznIntMod,
        "int_ne" => FznIntNe,
        "int_ne_reif" => FznIntNeReif,
        "int_plus" => FznIntPlus,
        "int_pow" => FznIntPow,
        "int_times" => FznIntTimes,
        # Booleans. 
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#bool-flatzinc-builtins
        "array_bool_and" => FznArrayBoolAnd,
        "array_bool_element" => FznArrayBoolElement,
        "array_bool_or" => FznArrayBoolOr,
        "array_bool_xor" => FznArrayBoolXor,
        "array_var_bool_element" => FznArrayVarBoolElement,
        "bool2int" => FznBoolToInt,
        "bool_and" => FznBoolAnd,
        "bool_clause" => FznBoolClause, # Reif below.
        "bool_eq" => FznBoolEq,
        "bool_eq_reif" => FznBoolEqReif,
        "bool_le" => FznBoolLe,
        "bool_le_reif" => FznBoolLeReif,
        "bool_lin_eq" => FznBoolLinEq, # No _reif.
        "bool_lin_le" => FznBoolLinLe, # No _reif.
        "bool_lt" => FznBoolLt,
        "bool_lt_reif" => FznBoolLtReif,
        "bool_not" => FznBoolNot,
        "bool_or" => FznBoolOr,
        "bool_xor" => FznBoolXor, # No _reif, even though the doc seems to imply its existence.
        # Sets.
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#set-flatzinc-builtins
        "array_set_element" => FznArraySetElement,
        "array_var_set_element" => FznArrayVarSetElement,
        "set_card" => FznSetCard,
        "set_diff" => FznSetDiff,
        "set_eq" => FznSetEq,
        "set_eq_reif" => FznSetEqReif,
        "set_in" => FznSetIn,
        "set_in_reif" => FznSetInReif,
        "set_intersect" => FznSetIntersect,
        "set_le" => FznSetLe,
        "set_le_reif" => FznSetLeReif,
        "set_lt" => FznSetLt,
        "set_lt_reif" => FznSetLtReif,
        "set_ne" => FznSetNe,
        "set_ne_reif" => FznSetNeReif,
        "set_subset" => FznSetSubset,
        "set_subset_reif" => FznSetSubsetReif,
        "set_superset" => FznSetSuperset,
        "set_superset_reif" => FznSetSupersetReif,
        "set_symdiff" => FznSetSymdiff,
        "set_union" => FznSetUnion,
        # Floats.
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#float-flatzinc-builtins
        "array_float_element" => FznArrayFloatElement,
        "array_float_maximum" => FznArrayFloatMaximum,
        "array_float_minimum" => FznArrayFloatMinimum,
        "array_var_float_element" => FznArrayVarFloatElement,
        "float_abs" => FznFloatAbs,
        "float_acos" => FznFloatAcos,
        "float_acosh" => FznFloatAcosh,
        "float_asin" => FznFloatAsin,
        "float_asinh" => FznFloatAsinh,
        "float_atan" => FznFloatAtan,
        "float_atanh" => FznFloatAtanh,
        "float_cos" => FznFloatCos,
        "float_cosh" => FznFloatCosh,
        "float_div" => FznFloatDiv,
        "float_dom" => FznFloatDom,
        "float_eq" => FznFloatEq,
        "float_eq_reif" => FznFloatEqReif,
        "float_exp" => FznFloatExp,
        "float_in" => FznFloatIn,
        "float_in_reif" => FznFloatInReif,
        "float_le" => FznFloatLe,
        "float_le_reif" => FznFloatLeReif,
        "float_lin_eq" => FznFloatLinEq,
        "float_lin_eq_reif" => FznFloatLinEqReif,
        "float_lin_le" => FznFloatLinLe,
        "float_lin_le_reif" => FznFloatLinLeReif,
        "float_lin_lt" => FznFloatLinLt,
        "float_lin_lt_reif" => FznFloatLinLtReif,
        "float_lin_ne" => FznFloatLinNe,
        "float_lin_ne_reif" => FznFloatLinNeReif,
        "float_ln" => FznFloatLn,
        "float_log10" => FznFloatLog10,
        "float_log2" => FznFloatLog2,
        "float_lt" => FznFloatLt,
        "float_lt_reif" => FznFloatLtReif,
        "float_max" => FznFloatMax,
        "float_min" => FznFloatMin,
        "float_ne" => FznFloatNe,
        "float_ne_reif" => FznFloatNeReif,
        "float_plus" => FznFloatPlus,
        "float_pow" => FznFloatPow,
        "float_sin" => FznFloatSin,
        "float_sinh" => FznFloatSinh,
        "float_sqrt" => FznFloatSqrt,
        "float_tan" => FznFloatTan,
        "float_tanh" => FznFloatTanh,
        "float_times" => FznFloatTimes,
        "int2float" => FznIntToFloat,
        # New in MiniZinc 2.0.0. Most of them are already included above.
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-0-0
        "bool_clause_reif" => FznBoolClauseReif,
        # New in MiniZinc 2.0.2.
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-0-2
        "array_var_bool_element_nonshifted" =>
            FznArrayVarBoolElementNonshifted,
        "array_var_float_element_nonshifted" =>
            FznArrayVarFloatElementNonshifted,
        "array_var_int_element_nonshifted" =>
            FznArrayVarIntElementNonshifted,
        "array_var_set_element_nonshifted" =>
            FznArrayVarSetElementNonshifted,
        # New in MiniZinc 2.1.0. All of them are already included above.
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-1-0
        # New in MiniZinc 2.1.1. Unimplementable here.
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-1-1
        # New in MiniZinc 2.2.1. 
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-2-1
        "int_pow_fixed" => FznIntPowFixed,
        # New in MiniZinc 2.3.3. 
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-3-3
        "float_set_in" => FznFloatSetInt,
        # New in MiniZinc 2.5.2. 
        # https://www.minizinc.org/doc-2.5.5/en/lib-flatzinc.html#flatzinc-builtins-added-in-minizinc-2-5-2
        "array_var_bool_element2d_nonshifted" =>
            FznArrayVarBoolElement2DNonshifted,
        "array_var_float_element2d_nonshifted" =>
            FznArrayVarFloatElement2DNonshifted,
        "array_var_int_element2d_nonshifted" =>
            FznArrayVarIntElement2DNonshifted,
        "array_var_set_element2d_nonshifted" =>
            FznArrayVarSetElement2DNonshifted,
    )
    return mapping[cons_verb]
end

function parse_constraint_arguments(cons_args::Vector)
    args = Any[]

    for a in cons_args
        if typeof(a) <: Vector
            push!(args, parse_constraint_arguments(a))
        else
            push!(args, parse_basic_expression(a))
        end
    end

    return args
end

function parse_basic_expression(expr::AbstractString)
    # Far from type stability, but hard to avoid: the output might be a 
    # Boolean, a number, or a variable, without a way to know it beforehand.

    # Simplest cases: Boolean constants.
    if expr == "true"
        return true
    end
    if expr == "false"
        return false
    end

    # Try to parse as an integer or a float.
    try
        return parse(Int, expr)
    catch
        # Do nothing.
    end
    try
        return parse(Float64, expr)
    catch
        # Do nothing.
    end

    # Nothing matched: it must be a variable.
    return expr
end

# -----------------------------------------------------------------------------
# - String-level parsing functions. This section corresponds to a tokenizer.
# -----------------------------------------------------------------------------

function get_fzn_item(io::IO)
    # A FlatZinc item is delimited by a semicolon (;) at the end. Return one 
    # complete such item, excluding any comments.
    item = ""
    while !eof(io)
        c = read(io, Char)

        # A comment starts with a percent (%) and ends at the end of the line.
        # Stop reading this character and continue normally at the next line.
        if c == '%'
            readline(io)

            # If something was read, return this item. If not, continue reading.
            if length(string(strip(item))) == 0
                continue
            else
                break
            end
        end

        # Push the new character into the string.
        item *= c

        # An item is delimited by a semicolon.
        if c == ';'
            break
        end
    end
    return string(strip(item))
end

function split_variable(item::AbstractString)
    # Typical input: "var int: x1;" -> scalar
    # Complex input: "array [1..5] of var int: x1;" -> array
    # Complex input: "var int: x1 :: some_annotation = some_value;" -> scalar
    # Complex input: "var int: x1 :: some_annotation :: some_other_annotation;" -> scalar

    @assert length(item) > 5

    # Get rid of the semicolon (;) at the end.
    @assert item[end] == ';'
    item = lstrip(item[1:end-1])

    # Detect whether this is one variable or an array of variables.
    if startswith(item, "var")
        return split_variable_scalar(item)
    elseif startswith(item, "array") && occursin("var", item)
        return split_variable_array(item)
    else
        @assert false
    end
end

function split_variable_scalar(item::AbstractString)
    # Get rid of the "var" keyword at the beginning. 
    @assert length(item) > 3
    @assert item[1:3] == "var"
    item = lstrip(item[4:end])

    # Split on the colon (:): the type of the variable is before.
    var_type, item = split(item, ':', limit=2)
    var_type = strip(var_type)
    item = lstrip(item)

    # Potentially split on the double colon (::) to detect annotations, then
    # on the equal (=) to detect literal values. There may be several 
    # annotations.
    if occursin("::", item)
        var_name, item = split(item, "::", limit=2)
        var_name = strip(var_name)
        item = lstrip(item)

        if occursin('=', item)
            var_annotations, var_value = split(item, '=', limit=2)
            var_annotations = strip(var_annotations)
            var_value = strip(var_value)
        else
            var_annotations = strip(item)
            var_value = ""
        end

        var_annotations = split(var_annotations, "::")
        var_annotations = map(strip, var_annotations)
    else
        var_annotations = [""]

        if occursin('=', item)
            var_name, var_value = split(item, '=', limit=2)
            var_name = strip(var_name)
            var_value = strip(var_value)
        else
            var_name = strip(item)
            var_value = ""
        end
    end

    return ("", var_type, var_name, var_annotations, var_value)
end

function split_variable_array(item::AbstractString)
    # Get rid of the "array" keyword at the beginning. 
    @assert length(item) > 5
    @assert item[1:5] == "array"
    item = lstrip(item[6:end])

    # Split on the "of" keyword: the array definition is before, the rest is a 
    # normal variable definition.
    var_array, item = split(item, "of", limit=2)
    var_array = strip(var_array)
    item = string(lstrip(item))

    # Parse the rest of the line.
    _, var_type, var_name, var_annotations, var_value =
        split_variable_scalar(item)

    return (var_array, var_type, var_name, var_annotations, var_value)
end

function split_solve(item::AbstractString)
    # Typical input: "solve satisfy;", "solve minimize x1;", "solve maximize x1;"

    @assert length(item) > 5

    # Get rid of the semicolon (;) at the end.
    @assert item[end] == ';'
    item = lstrip(item[1:end-1])

    # Get rid of the "var" keyword at the beginning. 
    @assert item[1:5] == "solve"
    item = lstrip(item[6:end])

    # Three operators are possible. 
    if startswith(item, "satisfy")
        return (FznSatisfy, nothing)
    elseif startswith(item, "minimize")
        item = strip(item[9:end])
        return (FznMinimise, item)
    elseif startswith(item, "maximize")
        item = strip(item[9:end])
        return (FznMaximise, item)
    end
    @assert false
end

function split_constraint(item::AbstractString)
    # Typical input: "constraint int_le(0, x);"

    @assert length(item) > 10

    # Get rid of the "constraint" keyword at the beginning. 
    @assert item[1:10] == "constraint"
    item = lstrip(item[11:end])

    # Get rid of the semicolon (;) at the end.
    @assert item[end] == ';'
    item = lstrip(item[1:end-1])

    # Locate the verb of the constraint.
    cons_verb, item = split(item, '(', limit=2)
    cons_verb = strip(cons_verb)
    item = lstrip(item)

    # Check whether annotations are present.
    if occursin("::", item)
        item, cons_annotations = split(item, "::", limit=2)
        item = rstrip(item)
        cons_annotations = strip(cons_annotations)
    else
        cons_annotations = nothing
    end

    # Eliminate the closing parenthesis.
    @assert item[end] == ')'
    cons_args = lstrip(item[1:end-1])

    return (cons_verb, cons_args, cons_annotations)
end

function split_constraint_arguments(
    cons_args::AbstractString,
)::FZN_UNPARSED_ARGUMENT_LIST
    # Typical input: "0, x"

    @assert length(cons_args) > 0

    # Arguments are separated with commas: if there is none, there is just 
    # one argument.
    if !occursin(',', cons_args)
        return [cons_args]
    end

    # There are only two types of arguments: basic ones and arrays.
    # - Basic expressions: either a constant or a variable identifier.
    # - Array expressions: a series of basic expressions between square 
    #   brackets, separated by commas. An array cannot be contained in an 
    #   array (this simplified the code enormously).

    args = FZN_UNPARSED_ARGUMENT[]
    while length(cons_args) > 0
        if cons_args[1] == '['
            # Start of array: find the end of the array, parse between.
            index = findfirst(']', cons_args)
            array = strip(cons_args[2:index-1])
            cons_args = strip(cons_args[index+1:end])

            # If there is a comma after the array, consume it.
            if occursin(',', cons_args)
                index = findfirst(',', cons_args)
                cons_args = lstrip(cons_args[index+1:end])
            end

            # Parse the contents of the array.
            array_args = AbstractString[]
            while length(array) > 0
                # Basic expression: find the next comma if there is one.
                if !occursin(',', array)
                    push!(array_args, array)
                    break
                else
                    index = findfirst(',', array)
                    arg = strip(array[1:index-1])
                    array = strip(array[index+1:end])

                    push!(array_args, arg)
                end
            end

            push!(args, array_args)
        else
            # Basic expression: find the next comma if there is one.
            if !occursin(',', cons_args)
                push!(args, cons_args)
                break
            else
                index = findfirst(',', cons_args)
                arg = strip(cons_args[1:index-1])
                cons_args = strip(cons_args[index+1:end])

                push!(args, arg)
            end
        end
    end

    return args
end
