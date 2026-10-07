"""
    Contiguity(dimension::Int)

Ensures that, in the binary variables `x` constrained to be in this set, 
all the 1s are contiguous. The vector must correspond to the regular expression
`0*1*0*`.
"""
struct Contiguity <: MOI.AbstractVectorSet
    dimension::Int
end

# isbits types, nothing to copy
function copy(set::Contiguity)
    return set
end
