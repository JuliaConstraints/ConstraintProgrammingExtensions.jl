# DCP requires a few information from each "atom":
# - its sign (`Base.sign`): whether its value is always positive (1.0), 
#   always negative (-1.0), or always zero (0.0). When no sign can be 
#   assigned, `Base.sign` returns `x/|x|`, but this does not make sense for 
#   abstract math formulae: hence, return NaN. 
# - its monotonicity (`monotonicity`): whether the value of the atom is 
#   nondecreasing/nonincreasing when its argument is nondecreasing, indicated
#   by the enumeration `Monotonicity`.
# - its curvature (`curvature`): whether the atom describes an affine, convex, 
#   or concave function with respect to its argument, indicated by the 
#   enumeration `Curvature`.

sign(::MOI.AbstractFunction) = NaN # Type piracy for now, unless merged into MOI... 

@enum Monotonicity ConstantMonotonic Nondecreasing Nonincreasing Nonmonotonic
monotonicity(::MOI.AbstractFunction) = Nonmonotonic

@enum Curvature Constant Affine Convex Concave Nonconvex
curvature(::MOI.AbstractFunction) = Nonmonotonic
