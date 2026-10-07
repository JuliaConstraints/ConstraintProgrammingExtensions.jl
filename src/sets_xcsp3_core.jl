"""A scalar argument referring to a 1-based position in the constrained MOI vector."""
struct XCSP3Position <: AbstractXCSP3Argument
    index::Int
    function XCSP3Position(index::Int)
        index > 0 || throw(ArgumentError("positions start at 1"))
        new(index)
    end
end

"""An array of 1-based positions; its shape is preserved when binding an assignment."""
struct XCSP3Positions{A <: AbstractArray{Int}} <: AbstractXCSP3Argument
    indices::A
    function XCSP3Positions(indices::A) where {A <: AbstractArray{Int}}
        Base.require_one_based_indexing(indices)
        all(>(0), indices) || throw(ArgumentError("positions start at 1"))
        storage = copy(indices)
        new{typeof(storage)}(storage)
    end
end

const XCSP3_OPERATORS = (:neg, :abs, :sqr, :add, :sub, :mul, :div, :mod, :pow,
    :min, :max, :dist, :lt, :le, :ge, :gt, :ne, :eq, :set, :in, :notin,
    :not, :and, :or, :xor, :iff, :imp, :if)

"""Typed XCSP3 expression tree. Leaves are constants or XCSP3Position references; never Julia eval."""
struct XCSP3Expression{A <: Tuple}
    operator::Symbol
    arguments::A
    function XCSP3Expression(operator::Symbol, arguments...)
        operator in XCSP3_OPERATORS || throw(ArgumentError("unsupported XCSP3 expression operator $operator"))
        n = length(arguments)
        valid = operator in (:neg, :abs, :sqr, :not) ? n == 1 :
            operator == :if ? n == 3 : operator == :set ? true :
            operator in (:add, :mul, :min, :max, :eq, :and, :or, :xor, :iff) ? n >= 2 : n == 2
        valid || throw(ArgumentError("invalid arity for $operator"))
        new{typeof(arguments)}(operator, arguments)
    end
end

"""Wildcard cell of a starred extension table."""
struct XCSP3Star end

Base.:(==)(a::XCSP3Position, b::XCSP3Position) = a.index == b.index
Base.:(==)(a::XCSP3Positions, b::XCSP3Positions) = a.indices == b.indices
Base.:(==)(a::XCSP3Expression, b::XCSP3Expression) = a.operator == b.operator && a.arguments == b.arguments
Base.:(==)(::XCSP3Star, ::XCSP3Star) = true
Base.copy(a::XCSP3Position) = a
Base.copy(a::XCSP3Positions) = XCSP3Positions(a.indices)

# New positional forms also support condition operands; implicit sequential
# XCSP3Variable operands remain available in the earlier dedicated carriers.
const _CORE_KEYS = (
    intension = (:expression,), extension = (:list, :tuples, :positive),
    regular = (:list, :transitions, :start, :final), mdd = (:list, :transitions, :start, :final),
    all_different = (:list, :lists, :matrix, :except), all_equal = (:list,),
    sum = (:list, :coefficients, :condition), count = (:list, :values, :condition),
    nvalues = (:list, :except, :condition),
    ordered = (:list, :lengths, :operator), lex = (:lists, :matrix, :operator),
    precedence = (:list, :values, :covered),
    minimum = (:list, :index, :rank, :start_index, :condition),
    maximum = (:list, :index, :rank, :start_index, :condition),
    element = (:list, :matrix, :index, :row_index, :column_index, :rank, :start_index,
        :row_start, :column_start, :condition, :value),
    channel = (:list, :second, :value, :start_index, :second_start),
    stretch = (:list, :values, :widths, :patterns),
    no_overlap = (:origins, :lengths, :dim, :zero_ignored),
    cumulative = (:origins, :lengths, :heights, :ends, :condition),
    bin_packing = (:list, :sizes, :condition, :conditions, :loads, :start_index),
    knapsack = (:list, :weights, :profits, :weight_condition, :profit_condition),
    instantiation = (:list, :values),
    circuit = (:list, :size, :start_index),
    slide = (:lists, :offsets, :collects, :circular, :template),
)

const _CORE_REQUIRED = (
    intension = (:expression,), extension = (:list, :tuples),
    regular = (:list, :transitions, :start, :final), mdd = (:list, :transitions),
    all_different = (), all_equal = (:list,), ordered = (:list,), lex = (),
    sum = (:list, :condition), count = (:list, :values, :condition), nvalues = (:list, :condition),
    precedence = (:list,), minimum = (:list,), maximum = (:list,), element = (),
    channel = (:list,), stretch = (:list, :values, :widths),
    no_overlap = (:origins, :lengths), cumulative = (:origins, :lengths, :heights, :condition),
    bin_packing = (:list, :sizes), knapsack = (:list, :weights, :profits, :weight_condition, :profit_condition),
    instantiation = (:list, :values), circuit = (:list,), slide = (:lists, :offsets, :collects, :template),
)

function _core_signature(family, args)
    all(key -> haskey(args, key), getproperty(_CORE_REQUIRED, family)) ||
        throw(ArgumentError("missing required argument for $family"))
    if family in (:all_different, :lex)
        forms = family == :all_different ? (:list, :lists, :matrix) : (:lists, :matrix)
        count(key -> haskey(args, key), forms) == 1 ||
            throw(ArgumentError("provide lists or matrix, not both"))
    elseif family in (:minimum, :maximum)
        haskey(args, :index) || haskey(args, :condition) || throw(ArgumentError("extremum requires index or condition"))
    elseif family == :element
        count(key -> haskey(args, key), (:list, :matrix)) == 1 || throw(ArgumentError("element requires list or matrix"))
        count(key -> haskey(args, key), (:value, :condition)) == 1 || throw(ArgumentError("element requires value or condition"))
        if haskey(args, :matrix)
            haskey(args, :row_index) && haskey(args, :column_index) || throw(ArgumentError("matrix element indices"))
            haskey(args, :index) && throw(ArgumentError("matrix element uses row/column indices"))
        end
    elseif family == :channel
        haskey(args, :second) && haskey(args, :value) && throw(ArgumentError("channel forms cannot be combined"))
    elseif family == :bin_packing
        count(key -> haskey(args, key), (:loads, :condition, :conditions)) == 1 || throw(ArgumentError("bin packing requires one condition form"))
    elseif family == :slide
        args.template isa MOI.AbstractVectorSet || throw(ArgumentError("slide template must be an MOI vector set"))
        all(>(0), args.offsets) && all(>(0), args.collects) || throw(ArgumentError("positive offsets and collects required"))
    end
    return nothing
end

function _validate_core_argument(value, dimension)
    _is_moi_index(value) && throw(ArgumentError("MOI indices belong in the constrained function"))
    if value isa XCSP3Position
        value.index <= dimension || throw(DimensionMismatch("position exceeds function dimension"))
    elseif value isa XCSP3Positions
        all(<=(dimension), value.indices) || throw(DimensionMismatch("position exceeds function dimension"))
    elseif value isa XCSP3Expression
        foreach(x -> _validate_core_argument(x, dimension), value.arguments)
    elseif value isa XCSP3Condition
        _validate_core_argument(value.operand, dimension)
    elseif value isa Union{XCSP3Constant, XCSP3Constants, XCSP3ValueSet}
        _validate_core_argument(value isa XCSP3Constant ? value.value : value.values, dimension)
    elseif value isa Union{XCSP3Variable, XCSP3Variables}
        throw(ArgumentError("use XCSP3Position(s) in general core carriers; sequential arguments are ambiguous here"))
    elseif value isa Union{AbstractArray, Tuple, NamedTuple, AbstractSet}
        foreach(x -> _validate_core_argument(x, dimension), value)
    elseif value isa Pair
        _validate_core_argument(first(value), dimension)
        _validate_core_argument(last(value), dimension)
    elseif value isa AbstractDict
        foreach(x -> _validate_core_argument(x, dimension), pairs(value))
    elseif value isa Function
        throw(ArgumentError("use typed XCSP3Expression trees, not opaque functions"))
    end
    return nothing
end

"""
    XCSP3Core{family}(dimension; arguments...)

Provisional core modelling carrier. Arguments use XCSP3Position(s) for decision
values, constants otherwise. Explicit positions permit repeated variable roles,
mixed constant/variable arrays and expression-valued lists. Arrays use Julia
column-major ordering. Index-valued variables use explicit `start_index` metadata
(default 1); an XML frontend must pass 0 when using XCSP3's default.

Named aliases include XCSP3Minimum, XCSP3Maximum, XCSP3Element, XCSP3NoOverlap,
XCSP3Cumulative, XCSP3Regular, XCSP3MDD, and the other remaining core families.
Constraint semantics and error functions do not belong to this carrier.
"""
struct XCSP3Core{K, A <: NamedTuple} <: MOI.AbstractVectorSet
    dimension::Int
    arguments::A
    function XCSP3Core{K}(dimension::Int; arguments...) where {K}
        haskey(_CORE_KEYS, K) || throw(ArgumentError("unknown core family $K"))
        dimension >= 0 || throw(ArgumentError("negative dimension"))
        all(key -> key in getproperty(_CORE_KEYS, K), keys(arguments)) ||
            throw(ArgumentError("unknown argument for $K"))
        args = (; arguments...)
        _core_signature(K, args)
        _validate_core_argument(args, dimension)
        get(args, :rank, :any) in (:any, :first, :last) || throw(ArgumentError("invalid index rank"))
        get(args, :operator, :le) in (:lt, :le, :ge, :gt) || throw(ArgumentError("invalid ordering operator"))
        return new{K, typeof(args)}(dimension, deepcopy(args))
    end
end
MOI.dimension(set::XCSP3Core) = set.dimension
Base.copy(set::XCSP3Core{K}) where {K} = XCSP3Core{K}(set.dimension; deepcopy(set.arguments)...)
Base.:(==)(a::XCSP3Core{K}, b::XCSP3Core{K}) where {K} = a.dimension == b.dimension && a.arguments == b.arguments
Base.:(==)(::XCSP3Core, ::XCSP3Core) = false

for (name, family) in ((:XCSP3Intension, :intension), (:XCSP3Extension, :extension),
        (:XCSP3Regular, :regular), (:XCSP3MDD, :mdd), (:XCSP3AllDifferentLists, :all_different),
        (:XCSP3AllEqual, :all_equal), (:XCSP3Ordered, :ordered), (:XCSP3Lex, :lex),
        (:XCSP3Precedence, :precedence), (:XCSP3Minimum, :minimum), (:XCSP3Maximum, :maximum),
        (:XCSP3Element, :element), (:XCSP3Channel, :channel), (:XCSP3Stretch, :stretch),
        (:XCSP3NoOverlap, :no_overlap), (:XCSP3Cumulative, :cumulative),
        (:XCSP3BinPacking, :bin_packing), (:XCSP3Knapsack, :knapsack),
        (:XCSP3Instantiation, :instantiation), (:XCSP3Circuit, :circuit), (:XCSP3Slide, :slide))
    @eval const $name = XCSP3Core{$(QuoteNode(family))}
end
