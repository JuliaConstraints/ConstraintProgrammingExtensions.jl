"""
    AbsoluteValue()

Ensures that the first variable is the absolute value of the second one. 
"""
struct AbsoluteValue <: MOI.AbstractVectorSet
end

MOI.dimension(set::AbsoluteValue) = 2
copy(set::AbsoluteValue) = set
Base.:(==)(::AbsoluteValue, ::AbsoluteValue) = true

"""
    Modulo()

Ensures that the three variables are related as: 

``x \\mod y \\equiv z``
"""
struct Modulo <: MOI.AbstractVectorSet
end

MOI.dimension(set::Modulo) = 3
copy(set::Modulo) = set
Base.:(==)(::Modulo, ::Modulo) = true
