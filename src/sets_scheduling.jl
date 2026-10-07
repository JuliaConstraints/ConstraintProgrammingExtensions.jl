"""
CumulativeResourceDeadlineType

Whether resources in `CumulativeResource` constraint have deadlines:

* either there are no deadlines: `NO_DEADLINE_CUMULATIVE_RESOURCE`
* or deadlines are given as variables: `VARIABLE_DEADLINE_CUMULATIVE_RESOURCE`
"""
@enum CumulativeResourceDeadlineType begin
    NO_DEADLINE_CUMULATIVE_RESOURCE
    VARIABLE_DEADLINE_CUMULATIVE_RESOURCE
end

"""
    CumulativeResource{CRDT}(n_tasks::Int)

This set models most variants of task scheduling with cumulative resource 
usage. Presence of deadlines can be indicated with the 
`CumulativeResourceDeadlineType` enumeration.

## Without deadline

Each task is given by a minimum start time (the first `n_tasks` variables), 
a duration (the next `n_tasks` variables), and the resource consumption 
(the following `n_tasks` variables). The final variable is the maximum amount of
the resource available.

Also called [`cumulative`](https://sofdem.github.io/gccat/gccat/Ccumulative.html).
This version does not consider end deadlines for tasks.

## With variable deadline

Each task is given by a minimum start time (the first `n_tasks` variables), 
a duration (the next `n_tasks` variables), a deadline (the following `n_tasks` 
variables), and the resource consumption (the next `n_tasks` variables). 
The final variable is the maximum amount of the resource available.

Also called [`cumulative`](https://sofdem.github.io/gccat/gccat/Ccumulative.html)
"""
struct CumulativeResource{CRDT} <: MOI.AbstractVectorSet
    n_tasks::Int
end

function CumulativeResource(n_tasks::Int)
    return CumulativeResource{NO_DEADLINE_CUMULATIVE_RESOURCE}(n_tasks)
end

MOI.dimension(set::CumulativeResource{NO_DEADLINE_CUMULATIVE_RESOURCE}) = 3 * set.n_tasks + 1
MOI.dimension(set::CumulativeResource{VARIABLE_DEADLINE_CUMULATIVE_RESOURCE}) = 4 * set.n_tasks + 1

"""
    NonOverlappingOrthotopesConditionalityType

Whether orthotopes in `NonOverlappingOrthotopes` constraint are considered:

* either all orthotopes must be considered: `UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES`
* or orthotopes can be disabled by variables: `CONDITIONAL_NONVERLAPPING_ORTHOTOPES`
"""
@enum NonOverlappingOrthotopesConditionalityType begin
    UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES
    CONDITIONAL_NONVERLAPPING_ORTHOTOPES
end

"""
    NonOverlappingOrthotopes{NOOCT}(n_orthotopes::Int, n_dimensions::Int)

This set corresponds to a guarantee that orthotopes do not overlap. Some 
orthotopes can optionally be disabled for the constraint (guided by variables),
based on the value of `NonOverlappingOrthotopesConditionalityType`.

## Unconditional constraint

Guarantees that the `n_orthotopes` orthotopes do not overlap. The orthotopes 
live in various dimensions: segments if `n_dimensions = 1`, rectangles if 
`n_dimensions = 2`, rectangular parallelepiped if `n_dimensions = 3`, 
hyperrectangles otherwise.

The variables are packed by orthotope: 

* the first `n_dimensions` are the origin of the orthotope
* the next `n_dimensions` are the size of the orthotope in each dimension
* the last `n_dimensions` are the destination of the orthotope. These variables
  are automatically constrained to be `origin + size` (unlike other modelling 
  layers, such as Gecode)

The set can be defined as: 

``(o_1, s_1, d_1, o_2, s_2, d_2 \\dots o_\\mathtt{o}, s_\\mathtt{o}, d_\\mathtt{o}) \\in \\mathbb{R}^{3 \\times \\mathtt{o} \\times \\mathtt{d} }``

Also called [`diffn`](https://sofdem.github.io/gccat/gccat/Cdiffn.html), 
`geost`, `nooverlap`, `diff2`, or `disjoint`.

### Example: two 2-D rectangles
    [x1, y1, w1, h1, x1e, y1e, x2, y2, w2, h2, x2e, y2e] in NonOverlappingOrthotopes(2, 2)
    # Enforces the following five constraints: 
    #   OR(
    #     x1 + w1 <= x2,
    #     x2 + w2 <= x1,
    #     y1 + h1 <= y2,
    #     y2 + h2 <= y1
    #   )
    #   x1e = x1 + w1
    #   y1e = y1 + h1
    #   x2e = x2 + w2
    #   y2e = y2 + h2

## Conditional constraint

Guarantees that the `n_orthotopes` orthotopes do not overlap, with a binary 
variable indicating whether a given orthotope must not overlap with other 
orthotopes (if 1) or if it can be ignored (if 0). The orthotopes live in 
various dimensions: segments if `n_dimensions = 1`, rectangles if 
`n_dimensions = 2`, rectangular parallelepiped if `n_dimensions = 3`, 
hyperrectangles otherwise.

The variables are packed by orthotope: 

* the first `n_dimensions` are the origin of the orthotope
* the next `n_dimensions` are the size of the orthotope in each dimension
* the next `n_dimensions` are the destination of the orthotope. These variables
  are automatically constrained to be `origin + size` (unlike other modelling 
  layers, such as Gecode)
* the last variable indicates whether the orthotope is mandatory (`true`) or 
  optional (`false`)

The set can be defined as: 

``(o_1, s_1, d_1, m_1, o_2, s_2, d_2, m_2 \\dots o_\\mathtt{o}, s_\\mathtt{o}, d_\\mathtt{o}, m_\\mathtt{o}) \\in \\prod_{i=1}^{\\mathtt{o}} (\\mathbb{R}^{3 \\times \\mathtt{d} \\times \\{0, 1\\}) }``

Also called [`diffn`](https://sofdem.github.io/gccat/gccat/Cdiffn.html), 
`nooverlap`, or `disjointconditional`.
"""
struct NonOverlappingOrthotopes{NOOCT} <: MOI.AbstractVectorSet
    n_orthotopes::Int
    n_dimensions::Int
end

function NonOverlappingOrthotopes(n_orthotopes::Int, n_dimensions::Int)
    return NonOverlappingOrthotopes{UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}(n_orthotopes, n_dimensions)
end

MOI.dimension(set::NonOverlappingOrthotopes{UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}) = 3 * set.n_orthotopes * set.n_dimensions
MOI.dimension(set::NonOverlappingOrthotopes{CONDITIONAL_NONVERLAPPING_ORTHOTOPES}) = 3 * set.n_orthotopes * set.n_dimensions + set.n_orthotopes

# isbits types, nothing to copy
function copy(
    set::Union{
        CumulativeResource, 
        NonOverlappingOrthotopes,
    },
)
    return set
end
