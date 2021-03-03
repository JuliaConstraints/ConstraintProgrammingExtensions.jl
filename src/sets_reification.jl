"""
    ReificationSet{S <: MOI.AbstractSet}(set::S)

``\\{(y, x) \\in \\{0, 1\\} \\times \\mathbb{R}^n | y = 1 \\iff x \\in set, y = 0 otherwise\\}``.

This set serves to find out whether a given constraint is satisfied.

The only possible values are 0 and 1 for the first variable of the set.
"""
struct ReificationSet{S <: MOI.AbstractSet} <: MOI.AbstractVectorSet
    set::S
end

MOI.dimension(set::ReificationSet{S}) where S = 1 + MOI.dimension(set.set)
Base.copy(set::ReificationSet{S}) where S = ReificationSet(copy(set.set))