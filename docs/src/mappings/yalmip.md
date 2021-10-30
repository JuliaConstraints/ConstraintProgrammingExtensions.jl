# Yalmip

Only CP constraints in Yalmip: 

* [`alldifferent`](https://yalmip.github.io/command/alldifferent/): mapped to [MILP constraints](https://github.com/yalmip/YALMIP/blob/develop/operators/alldifferent.m); `AllDifferent`
* [`iff`](https://yalmip.github.io/command/iff): mapped to binary variables, then MILP constraints; `Equivalence`
* [`implies`](https://yalmip.github.io/command/implies): `Implication`
* [`interp1`](https://github.com/yalmip/YALMIP/blob/develop/operators/interp1_internal.m), [`interp2`](https://github.com/yalmip/YALMIP/blob/develop/operators/interp2_internal.m): [`PiecewiseLinearOpt.jl`](https://github.com/joehuchette/PiecewiseLinearOpt.jl)
* [`max`](https://github.com/yalmip/YALMIP/blob/develop/operators/max_internal.m): mapped to binary variables, then MILP constraints; `MaximumAmong`
* [`min`](https://github.com/yalmip/YALMIP/blob/develop/operators/min_internal.m): mapped to binary variables, then MILP constraints; `MinimumAmong`
* [`nnz`](https://github.com/yalmip/YALMIP/blob/develop/operators/nnz_internal.m): mapped to binary variables, then MILP constraints; `Count`
* [`sumk`](https://github.com/yalmip/YALMIP/blob/develop/operators/sumk.m): sum of the `k` largest values; `Sort` and affine expressions
