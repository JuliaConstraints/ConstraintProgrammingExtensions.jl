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

# isbits types, nothing to copy
function Base.copy(
    set::Union{CumulativeResource, CumulativeResourceWithDeadline},
)
    return set
end
