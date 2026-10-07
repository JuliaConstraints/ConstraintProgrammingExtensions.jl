"""
    AbstractXCSP3Argument

Static description of where an XCSP3 argument is stored. These descriptors never contain
`MOI.VariableIndex` values: decision arguments are packed in the constrained vector.
"""
abstract type AbstractXCSP3Argument end

_is_moi_index(value) = value isa MOI.VariableIndex || value isa MOI.ConstraintIndex

"""A scalar XCSP3 argument fixed when the constraint is constructed."""
struct XCSP3Constant{T} <: AbstractXCSP3Argument
    value::T

    function XCSP3Constant(value::T) where {T}
        _is_moi_index(value) && throw(ArgumentError(
            "decision-variable and constraint indices belong in the MOI function"))
        return new{T}(value)
    end
end
Base.:(==)(left::XCSP3Constant, right::XCSP3Constant) = left.value == right.value

"""
    XCSP3Variable()

A scalar XCSP3 argument supplied as the next entry of the constrained vector.
"""
struct XCSP3Variable <: AbstractXCSP3Argument end
Base.:(==)(::XCSP3Variable, ::XCSP3Variable) = true

"""A vector XCSP3 argument fixed when the constraint is constructed."""
struct XCSP3Constants{T, V <: AbstractVector{T}} <: AbstractXCSP3Argument
    values::V

    function XCSP3Constants(values::V) where {T, V <: AbstractVector{T}}
        any(_is_moi_index, values) && throw(ArgumentError(
            "decision-variable and constraint indices belong in the MOI function"))
        return new{T, V}(values)
    end
end

Base.:(==)(left::XCSP3Constants, right::XCSP3Constants) = left.values == right.values

"""A vector XCSP3 argument supplied by `length` consecutive constrained entries."""
struct XCSP3Variables <: AbstractXCSP3Argument
    length::Int

    function XCSP3Variables(length::Int)
        length > 0 || throw(ArgumentError("an XCSP3 variable group must be nonempty"))
        return new(length)
    end
end
Base.:(==)(left::XCSP3Variables, right::XCSP3Variables) = left.length == right.length


"""Closed constant interval used as the operand of an XCSP3 condition."""
struct XCSP3Interval{T} <: AbstractXCSP3Argument
    lower::T
    upper::T

    function XCSP3Interval(lower::T, upper::T) where {T}
        lower <= upper || throw(ArgumentError("an XCSP3 interval cannot be decreasing"))
        return new{T}(lower, upper)
    end
end
Base.:(==)(left::XCSP3Interval, right::XCSP3Interval) =
    left.lower == right.lower && left.upper == right.upper

"""A constant set used as the operand of an XCSP3 condition."""
struct XCSP3ValueSet{T, S <: AbstractSet{T}} <: AbstractXCSP3Argument
    values::S

    function XCSP3ValueSet(values::S) where {T, S <: AbstractSet{T}}
        any(_is_moi_index, values) && throw(ArgumentError(
            "decision-variable and constraint indices belong in the MOI function"))
        return new{T, S}(values)
    end
end
Base.:(==)(left::XCSP3ValueSet, right::XCSP3ValueSet) = left.values == right.values


const _XCSP3_CONDITION_OPERATORS = (:eq, :ne, :lt, :le, :gt, :ge, :in, :notin)

"""
    XCSP3Condition(operator, operand)

An XCSP3 condition. `operand` is an [`XCSP3Constant`](@ref),
[`XCSP3Variable`](@ref), [`XCSP3Interval`](@ref), or [`XCSP3ValueSet`](@ref). A
variable operand is placed in the constrained vector, never in this set.
"""
struct XCSP3Condition{O <: AbstractXCSP3Argument}
    operator::Symbol
    operand::O

    function XCSP3Condition(operator::Symbol, operand::O) where {O <: AbstractXCSP3Argument}
        operator in _XCSP3_CONDITION_OPERATORS ||
            throw(ArgumentError("unsupported XCSP3 condition operator: $operator"))
        membership_operator = operator in (:in, :notin)
        operand isa Union{XCSP3Constant, XCSP3Variable, XCSP3Interval, XCSP3ValueSet, XCSP3Position} ||
            throw(ArgumentError("an XCSP3 condition requires a scalar or membership operand"))
        membership_operand = operand isa Union{XCSP3Interval, XCSP3ValueSet}
        membership_operator == membership_operand || throw(ArgumentError(
            "operators in/notin require an interval or value set; scalar comparisons forbid both"))
        return new{O}(operator, operand)
    end
end
Base.:(==)(left::XCSP3Condition, right::XCSP3Condition) =
    left.operator == right.operator && left.operand == right.operand

XCSP3Condition(operator::Symbol, operand) =
    XCSP3Condition(operator, XCSP3Constant(operand))
XCSP3Condition(operator::Symbol, operand::AbstractSet) =
    XCSP3Condition(operator, XCSP3ValueSet(operand))


"""
    XCSP3AllDifferent(dimension; except = Int[])

Provisional exact-XCSP3 carrier for the list form of `allDifferent`. The constrained vector
contains the list variables; `except` contains only static values.
"""
struct XCSP3AllDifferent{T, V <: AbstractVector{T}} <: MOI.AbstractVectorSet
    dimension::Int
    except::V

    function XCSP3AllDifferent(dimension::Int, except::V) where {T, V <: AbstractVector{T}}
        dimension > 0 || throw(ArgumentError("allDifferent requires a nonempty list"))
        any(_is_moi_index, except) && throw(ArgumentError(
            "decision-variable and constraint indices belong in the MOI function"))
        return new{T, V}(dimension, except)
    end
end


function XCSP3AllDifferent(dimension::Int; except::AbstractVector = Int[])
    return XCSP3AllDifferent(dimension, except)
end

MOI.dimension(set::XCSP3AllDifferent) = set.dimension
Base.copy(set::XCSP3AllDifferent) = XCSP3AllDifferent(set.dimension, copy(set.except))
Base.:(==)(left::XCSP3AllDifferent, right::XCSP3AllDifferent) =
    left.dimension == right.dimension && left.except == right.except


"""
    XCSP3Sum(list_length; coefficients, condition)

Provisional exact-XCSP3 carrier for `sum`. Entries are packed in this 1-based order:

1. the `list_length` decision variables;
2. variable coefficients, when `coefficients isa XCSP3Variables`;
3. the condition operand, when it is an [`XCSP3Variable`](@ref).

Static coefficients and condition operands remain in the set. This layout supports the
XCSP3 forms with variable coefficients or a variable condition operand without storing a
decision-variable reference in an MOI set.
"""
struct XCSP3Sum{
        C <: Union{XCSP3Constants, XCSP3Variables},
        O <: AbstractXCSP3Argument,
    } <: MOI.AbstractVectorSet
    list_length::Int
    coefficients::C
    condition::XCSP3Condition{O}

    function XCSP3Sum(list_length::Int, coefficients::C,
            condition::XCSP3Condition{O}) where {
            C <: Union{XCSP3Constants, XCSP3Variables}, O <: AbstractXCSP3Argument}
        list_length > 0 || throw(ArgumentError("sum requires a nonempty list"))
        coefficient_length = coefficients isa XCSP3Variables ?
                             coefficients.length : length(coefficients.values)
        coefficient_length == list_length || throw(DimensionMismatch(
            "XCSP3 sum requires one coefficient per list entry"))
        return new{C, O}(list_length, coefficients, condition)
    end
end


function XCSP3Sum(list_length::Int;
        coefficients::Union{XCSP3Constants, XCSP3Variables} =
            XCSP3Constants(fill(1, list_length)),
        condition::XCSP3Condition)
    return XCSP3Sum(list_length, coefficients, condition)
end

function MOI.dimension(set::XCSP3Sum)
    coefficient_variables = set.coefficients isa XCSP3Variables ? set.list_length : 0
    operand_variables = set.condition.operand isa XCSP3Variable ? 1 : 0
    return set.list_length + coefficient_variables + operand_variables
end

function Base.copy(set::XCSP3Sum)
    coefficients = set.coefficients isa XCSP3Constants ?
                   XCSP3Constants(copy(set.coefficients.values)) : set.coefficients
    operand = if set.condition.operand isa XCSP3Constant
        XCSP3Constant(copy(set.condition.operand.value))
    elseif set.condition.operand isa XCSP3ValueSet
        XCSP3ValueSet(copy(set.condition.operand.values))
    else
        set.condition.operand
    end
    return XCSP3Sum(set.list_length, coefficients,
        XCSP3Condition(set.condition.operator, operand))
end
Base.:(==)(left::XCSP3Sum, right::XCSP3Sum) =
    left.list_length == right.list_length &&
    left.coefficients == right.coefficients && left.condition == right.condition

# Shared argument layouts. Mutable constants must not be shared by MOI.copy_to.
Base.copy(argument::XCSP3Constant) = XCSP3Constant(deepcopy(argument.value))
Base.copy(argument::XCSP3Constants) = XCSP3Constants(deepcopy(argument.values))
Base.copy(argument::XCSP3ValueSet) = XCSP3ValueSet(copy(argument.values))
Base.copy(argument::Union{XCSP3Variable, XCSP3Variables, XCSP3Interval}) = argument
Base.copy(condition::XCSP3Condition) =
    XCSP3Condition(condition.operator, copy(condition.operand))
_xcsp3_length(argument::XCSP3Constants) = length(argument.values)
_xcsp3_length(argument::XCSP3Variables) = argument.length
_xcsp3_variables(::AbstractXCSP3Argument) = 0
_xcsp3_variables(::XCSP3Variable) = 1
_xcsp3_variables(argument::XCSP3Variables) = argument.length

"""
    XCSP3Count(list_length; values, condition)

Count list entries belonging to `values`, then apply `condition`. Duplicate values
do not multiply the count. Pack the list, variable values (if any), and variable
condition operand (if any), in that order. Unary lists are supported.
"""
struct XCSP3Count{V <: Union{XCSP3Constants, XCSP3Variables}, O <: AbstractXCSP3Argument} <: MOI.AbstractVectorSet
    list_length::Int
    values::V
    condition::XCSP3Condition{O}
    function XCSP3Count(n::Int, values::V, condition::XCSP3Condition{O}) where {
            V <: Union{XCSP3Constants, XCSP3Variables}, O <: AbstractXCSP3Argument}
        n > 0 || throw(ArgumentError("count requires a nonempty list"))
        return new{V, O}(n, values, condition)
    end
end
XCSP3Count(n::Int; values, condition::XCSP3Condition) = XCSP3Count(n, values, condition)
MOI.dimension(set::XCSP3Count) =
    set.list_length + _xcsp3_variables(set.values) + _xcsp3_variables(set.condition.operand)
Base.copy(set::XCSP3Count) = XCSP3Count(set.list_length, copy(set.values), copy(set.condition))
Base.:(==)(a::XCSP3Count, b::XCSP3Count) =
    a.list_length == b.list_length && a.values == b.values && a.condition == b.condition

"""
    XCSP3NValues(list_length; except = Int[], condition)

Count distinct list values outside the constant `except` collection. Pack the list
followed by the condition operand if it is variable. All eight condition operators
are supported; a unary list and an empty set of counted distinct values are valid.
"""
struct XCSP3NValues{T, V <: AbstractVector{T}, O <: AbstractXCSP3Argument} <: MOI.AbstractVectorSet
    list_length::Int
    except::V
    condition::XCSP3Condition{O}
    function XCSP3NValues(n::Int, except::V, condition::XCSP3Condition{O}) where {
            T, V <: AbstractVector{T}, O <: AbstractXCSP3Argument}
        n > 0 || throw(ArgumentError("nValues requires a nonempty list"))
        any(_is_moi_index, except) && throw(ArgumentError("indices belong in the MOI function"))
        return new{T, V, O}(n, except, condition)
    end
end
XCSP3NValues(n::Int; except::AbstractVector = Int[], condition::XCSP3Condition) =
    XCSP3NValues(n, except, condition)
MOI.dimension(set::XCSP3NValues) = set.list_length + _xcsp3_variables(set.condition.operand)
Base.copy(set::XCSP3NValues) = XCSP3NValues(set.list_length, copy(set.except), copy(set.condition))
Base.:(==)(a::XCSP3NValues, b::XCSP3NValues) =
    a.list_length == b.list_length && a.except == b.except && a.condition == b.condition

"""
    XCSP3Cardinality(list_length; values, occurs, closed = false)

Constrain the occurrence count of each listed value. `values` and `occurs` are
[`XCSP3Constants`](@ref) or [`XCSP3Variables`](@ref). Constant occurrences are
nonnegative integers or nonempty ascending unit ranges of nonnegative integers.
The default is open (`closed=false`), as in XCSP3-core 3.2 and CPE's existing
`GlobalCardinality`. Packing order is list, variable values, variable occurrences. `closed=true`
also requires every list entry to belong to the counted values.

The all-variable `distribute` form additionally requires distinct counted values,
as specified by XCSP3. Constant occurrences may mix integers and intervals, a
semantic extension of the XML syntax. Unary lists are supported.
"""
struct XCSP3Cardinality{V <: Union{XCSP3Constants, XCSP3Variables},
        O <: Union{XCSP3Constants, XCSP3Variables}} <: MOI.AbstractVectorSet
    list_length::Int
    values::V
    occurs::O
    closed::Bool
    function XCSP3Cardinality(n::Int, values::V, occurs::O, closed::Bool) where {
            V <: Union{XCSP3Constants, XCSP3Variables},
            O <: Union{XCSP3Constants, XCSP3Variables}}
        n > 0 || throw(ArgumentError("cardinality requires a nonempty list"))
        _xcsp3_length(values) == _xcsp3_length(occurs) || throw(DimensionMismatch(
            "cardinality requires one occurrence specification per value"))
        if occurs isa XCSP3Constants
            all(occurs.values) do occurrence
                occurrence isa Integer && return occurrence >= 0
                return occurrence isa AbstractUnitRange{<:Integer} &&
                       !isempty(occurrence) && first(occurrence) >= 0
            end || throw(ArgumentError("occurrences must be nonnegative counts or ascending unit intervals"))
        end
        return new{V, O}(n, values, occurs, closed)
    end
end
XCSP3Cardinality(n::Int; values, occurs, closed::Bool = false) =
    XCSP3Cardinality(n, values, occurs, closed)
MOI.dimension(set::XCSP3Cardinality) =
    set.list_length + _xcsp3_variables(set.values) + _xcsp3_variables(set.occurs)
Base.copy(set::XCSP3Cardinality) =
    XCSP3Cardinality(set.list_length, copy(set.values), copy(set.occurs), set.closed)
Base.:(==)(a::XCSP3Cardinality, b::XCSP3Cardinality) =
    a.list_length == b.list_length && a.values == b.values &&
    a.occurs == b.occurs && a.closed == b.closed
