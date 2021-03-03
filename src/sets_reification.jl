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

"""
    EquivalenceSet{S1 <: MOI.AbstractSet, S2 <: MOI.AbstractSet}(set1::S1, set2::S2)

``\\{(x, y) \\in \\mathbb{R}^a \\times \\mathbb{R}^b} \\times \\mathbb{R}^n | x \\in S1 \\iff y \\in S2\\}``.

The two constraints must be either satisfied or not satisfied at the same time.
More explicitly, if the first one is satisfied, then the second one is implied
to be satisfied too; if the second one is satisfied, then the first one is 
implied.
"""
struct EquivalenceSet{S1 <: MOI.AbstractSet, S2 <: MOI.AbstractSet} <: MOI.AbstractVectorSet
    set1::S1
    set2::S2
end

MOI.dimension(set::EquivalenceSet{S, T}) where {S, T} = MOI.dimension(set.set1) + MOI.dimension(set.set2)
Base.copy(set::EquivalenceSet{S, T}) where {S, T} = EquivalenceSet(copy(set.set), copy(set.set2))

"""
    IfThenElseSet{
        Condition <: MOI.AbstractSet, 
        TrueConstraint <: MOI.AbstractSet, 
        FalseConstraint <: MOI.AbstractSet
    }(condition::Condition, true_constraint::TrueConstraint, false_constraint::FalseConstraint)

If the `condition` is satisfied, then the first constraint (of type 
`TrueConstraint`) will be implied. Otherwise, the second constraint
(of type `FalseConstraint`) will be implied.

``\\{(x, y, z) \\in \\{0, 1\\} \\times \\mathbb{R}^a \\times \\mathbb{R}^b \\times \\mathbb{R}^c | y \\in TrueConstraint \\iff x \\in set, z \\in FalseConstraint otherwise\\}``.
"""
struct IfThenElseSet{
    Condition <: MOI.AbstractSet, 
    TrueConstraint <: MOI.AbstractSet, 
    FalseConstraint <: MOI.AbstractSet
} <: MOI.AbstractVectorSet
    condition::Condition
    true_constraint::TrueConstraint
    false_constraint::FalseConstraint
end

MOI.dimension(set::IfThenElseSet{S, T, U}) where {S, T, U} = MOI.dimension(set.condition) + MOI.dimension(set.true_constraint) + MOI.dimension(set.false_constraint)
Base.copy(set::IfThenElseSet{S, T, U}) where {S, T, U} = ReificationSet(copy(set.condition), copy(set.true_constraint), copy(set.false_constraint))
