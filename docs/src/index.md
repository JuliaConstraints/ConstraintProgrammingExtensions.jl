# ConstraintProgrammingExtensions.jl

This package provides extensions to 
[MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl)
in order to support constraint programming. This allows to use the same user
model with several solvers. 

On top of providing a uniform interface, this package also implements a 
quantity of bridges, i.e. reformulations of constraints, to bridge the gap
when a solver does not support a specific constraint. In particular, the set 
of bridges should make it possible to transform any CP model into a MIP model.
