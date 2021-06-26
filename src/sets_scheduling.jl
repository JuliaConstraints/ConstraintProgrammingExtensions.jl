"""
    CumulativeResource(n_tasks::Int)

Each task is given by a minimum start time (the first `n_tasks` variables), 
a duration (the next `n_tasks` variables), and the resource consumption 
(the following `n_tasks` variables). The final variable is the maximum amount of
the resource available.

Also called [`cumulative`](https://sofdem.github.io/gccat/gccat/Ccumulative.html).
This version does not consider end deadlines for tasks.
"""
struct CumulativeResource <: MOI.AbstractVectorSet
    n_tasks::Int
end

MOI.dimension(set::CumulativeResource) = 3 * set.n_tasks + 1

"""
    CumulativeResourceWithDeadline(n_tasks::Int)

Each task is given by a minimum start time (the first `n_tasks` variables), 
a duration (the next `n_tasks` variables), a deadline (the following `n_tasks` 
variables), and the resource consumption (the next `n_tasks` variables). 
The final variable is the maximum amount of the resource available.

Also called [`cumulative`](https://sofdem.github.io/gccat/gccat/Ccumulative.html).
"""
struct CumulativeResourceWithDeadline <: MOI.AbstractVectorSet
    n_tasks::Int
end

MOI.dimension(set::CumulativeResourceWithDeadline) = 4 * set.n_tasks + 1

"""
    NonOverlappingOrthotopes(n_orthotopes::Int, n_dimensions::Int)

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

    ``(o_1, s_1, d_1, o_2, s_2, d_2 \\dots o_\\mathtt{orthotopes}, s_\\mathtt{orthotopes}, d_\\mathtt{orthotopes}) \\in \\mathbb{R}^{3 \\times \\mathtt{orthotopes} \\times \\mathtt{dimensions} }``

Also called [`diffn`](https://sofdem.github.io/gccat/gccat/Cdiffn.html), 
`geost`, `nooverlap`, `diff2`, or `disjoint`.

## Example: two 2-D rectangles
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
"""
struct NonOverlappingOrthotopes <: MOI.AbstractVectorSet
    n_orthotopes::Int
    n_dimensions::Int
end

MOI.dimension(set::NonOverlappingOrthotopes) = 3 * set.n_orthotopes * set.n_dimensions

"""
    ConditionallyNonOverlappingOrthotopes(n_orthotopes::Int, n_dimensions::Int)

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
* the last variable` indicates whether the orthotope is mandatory (`true`) or 
  optional (`false`)

The set can be defined as: 

    ``(o_1, s_1, d_1, m1, o_2, s_2, d_2, m2 \\dots o_\\mathtt{orthotopes}, s_\\mathtt{orthotopes}, d_\\mathtt{orthotopes}, m_\\mathtt{orthotopes}) \\in \\prod_{i=1}^{\\mathtt{orthotopes}} (\\mathbb{R}^{3 \\times \\mathtt{dimensions} \\times \\{0, 1\\}) }``

Also called [`diffn`](https://sofdem.github.io/gccat/gccat/Cdiffn.html), 
`nooverlap`, or `disjointconditional`.
"""
struct ConditionallyNonOverlappingOrthotopes <: MOI.AbstractVectorSet
    n_orthotopes::Int
    n_dimensions::Int
end

MOI.dimension(set::ConditionallyNonOverlappingOrthotopes) = 3 * set.n_orthotopes * set.n_dimensions + set.n_orthotopes

# isbits types, nothing to copy
function copy(
    set::Union{
        CumulativeResource, 
        CumulativeResourceWithDeadline, 
        NonOverlappingOrthotopes,
        ConditionallyNonOverlappingOrthotopes,
    },
)
    return set
end
