"""
    AbsoluteValue()

Ensures that the first variable is the absolute value of the second one. 
"""
struct AbsoluteValue <: MOI.AbstractVectorSet
end

MOI.dimension(set::AbsoluteValue) = 2
copy(set::AbsoluteValue) = set
Base.:(==)(::AbsoluteValue, ::AbsoluteValue) = true
