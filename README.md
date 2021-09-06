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

* [Chuffed.jl](https://github.com/dourouc05/Chuffed.jl), wrapper for the [Chuffed](https://github.com/chuffed/chuffed) solver
* [ConstraintSolver.jl](https://github.com/Wikunia/ConstraintSolver.jl), a native Julia solver
* [CPLEXCP.jl](https://github.com/dourouc05/CPLEXCP.jl), wrapper for the [CPLEX CP Optimizer](https://www.ibm.com/analytics/cplex-cp-optimizer) solver
