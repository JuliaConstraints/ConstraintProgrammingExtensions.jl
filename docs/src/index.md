# ConstraintProgrammingExtensions.jl

This package provides extensions to 
[MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl)
in order to support constraint programming. This allows to use the same user
model with several solvers. 

On top of providing a uniform interface, this package also implements a 
quantity of bridges, i.e. reformulations of constraints, to bridge the gap
when a solver does not support a specific constraint. In particular, the set 
of bridges should make it possible to transform any CP model into a MIP model.

## Citing ConstraintProgrammingExtensions

Currently, there is no article or preprint that can be cited for CPE. 
However, you can use the Zenodo DOI: 

```
@software{thibaut_cuvelier_2021_5122859,
  author       = {Thibaut Cuvelier and
                  Oscar Dowson},
  title        = {{dourouc05/ConstraintProgrammingExtensions.jl: 
                   v0.3.0}},
  month        = jul,
  year         = 2021,
  publisher    = {Zenodo},
  version      = {v0.3.0},
  doi          = {10.5281/zenodo.5122859},
  url          = {https://doi.org/10.5281/zenodo.5122859}
}
```
