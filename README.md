# ConstraintProgrammingExtensions.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](http://tcuvelier.be/ConstraintProgrammingExtensions.jl/dev/)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![The MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](http://opensource.org/licenses/MIT)
[![version](https://juliahub.com/docs/ConstraintProgrammingExtensions/version.svg)](https://juliahub.com/ui/Packages/ConstraintProgrammingExtensions/3CBBH)
[![DOI](https://zenodo.org/badge/240344723.svg)](https://zenodo.org/badge/latestdoi/240344723)

[![Continuous integration](https://github.com/dourouc05/ConstraintProgrammingExtensions.jl/actions/workflows/GitHubCI.yml/badge.svg)](https://github.com/dourouc05/ConstraintProgrammingExtensions.jl/actions/workflows/GitHubCI.yml/)
[![Coverage Status](https://coveralls.io/repos/dourouc05/ConstraintProgrammingExtensions.jl/badge.svg?branch=master)](https://coveralls.io/r/dourouc05/ConstraintProgrammingExtensions.jl?branch=master)
[![codecov.io](http://codecov.io/github/dourouc05/ConstraintProgrammingExtensions.jl/coverage.svg?branch=master)](http://codecov.io/github/dourouc05/ConstraintProgrammingExtensions.jl?branch=master)

This package provides extensions to 
[MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl)
in order to support constraint programming. This allows to use the same user
model with several solvers. 

On top of providing a uniform interface, this package also implements a 
quantity of bridges, i.e. reformulations of constraints, to bridge the gap
when a solver does not support a specific constraint. In particular, the set 
of bridges should make it possible to transform any CP model into a MIP model.

Currently, the following solvers are using this interface: 

* [Chuffed.jl](https://github.com/dourouc05/Chuffed.jl), wrapper for the open-source [Chuffed](https://github.com/chuffed/chuffed) solver
* [ConstraintSolver.jl](https://github.com/Wikunia/ConstraintSolver.jl), a native Julia open-source solver
* [CPLEXCP.jl](https://github.com/dourouc05/CPLEXCP.jl), wrapper for the commercial [CPLEX CP Optimizer](https://www.ibm.com/analytics/cplex-cp-optimizer) solver

## An example

For instance, you can use this package [to formulate a colouring problem on a map](https://github.com/dourouc05/ConstraintProgrammingExtensions.jl/blob/master/src/Test/test_integration.jl#L9-L32): 

```julia
model = … # Depending on the solver you want to use.

# Create the variables: six countriers; the value is the colour number for each country
belgium, _ = MOI.add_constrained_variable(model, MOI.Integer())
denmark, _ = MOI.add_constrained_variable(model, MOI.Integer())
france, _ = MOI.add_constrained_variable(model, MOI.Integer())
germany, _ = MOI.add_constrained_variable(model, MOI.Integer())
luxembourg, _ = MOI.add_constrained_variable(model, MOI.Integer())
netherlands, _ = MOI.add_constrained_variable(model, MOI.Integer())

# Constrain the colours to be in {0, 1, 2, 3}
MOI.add_constraint(model, belgium, MOI.Interval(0, 3))
MOI.add_constraint(model, denmark, MOI.Interval(0, 3))
MOI.add_constraint(model, france, MOI.Interval(0, 3))
MOI.add_constraint(model, germany, MOI.Interval(0, 3))
MOI.add_constraint(model, luxembourg, MOI.Interval(0, 3))
MOI.add_constraint(model, netherlands, MOI.Interval(0, 3))

# Two adjacent countries must have different colours.
countries(c1, c2) = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, -1], [c1, c2]), 0)
MOI.add_constraint(model, countries(belgium, france), CP.DifferentFrom(0))
MOI.add_constraint(model, countries(belgium, germany), CP.DifferentFrom(0))
MOI.add_constraint(model, countries(belgium, netherlands), CP.DifferentFrom(0))
MOI.add_constraint(model, countries(belgium, luxembourg), CP.DifferentFrom(0))
MOI.add_constraint(model, countries(denmark, germany), CP.DifferentFrom(0))
MOI.add_constraint(model, countries(france, germany), CP.DifferentFrom(0))
MOI.add_constraint(model, countries(france, luxembourg), CP.DifferentFrom(0))
MOI.add_constraint(model, countries(germany, luxembourg), CP.DifferentFrom(0))
MOI.add_constraint(model, countries(germany, netherlands), CP.DifferentFrom(0))

# Solve the model.
MOI.optimize!(model)

# Check if the solution is optimum.
@assert MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL

# Get the solution
@show MOI.get(model, MOI.VariablePrimal(), belgium)
@show MOI.get(model, MOI.VariablePrimal(), denmark)
@show MOI.get(model, MOI.VariablePrimal(), france)
@show MOI.get(model, MOI.VariablePrimal(), germany)
@show MOI.get(model, MOI.VariablePrimal(), luxembourg)
@show MOI.get(model, MOI.VariablePrimal(), netherlands)
```
