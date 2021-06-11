MiniZinc has a similar goal to this project: a common modelling interface for many underlying solvers. It is based on a similar concept to that of bridges, but with much less flexibility: each high-level constraint is mapped in a fixed way onto lower-level constraints.

* Bin packing: 
    * Raw: `CP.BinPacking` (with supplementary load variables)
        * [`bin_packing`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/bin_packing.mzn): mapped onto [a MILP-like model](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_bin_packing.mzn), but without binary variables (replaced by their definition in the capacity constraint: `bin[item] == value`). 
        * [`bin_packing_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/bin_packing.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_bin_packing_reif.mzn).
    * Capacitated: `CP.FixedCapacityBinPacking` and `CP.VariableCapacityBinPacking` (with supplementary load variables)
        * [`bin_packing_capa`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/bin_packing_capa.mzn): same MILP-like model [with a linear capacity constraint](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_bin_packing_capa.mzn).
        * [`bin_packing_capa_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/bin_packing_capa.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_bin_packing_capa_reif.mzn).
    * Load: `CP.BinPacking`
        * [`bin_packing_load`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/bin_packing_load.mzn): [similar MILP-like model](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_bin_packing_load.mzn).
        * [`bin_packing_load_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/bin_packing_load.mzn): [similar MILP-like model](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_bin_packing_load_reif.mzn).
    * Function: `CP.BinPacking` and `CP.BinPackingLoadFunction`
        * [`bin_packing_load_fn`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/bin_packing_load_fn.mzn) directly returns the load variables.
* Knapsack: `CP.ValuedKnapsack`
    * [`knapsack`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/knapsack.mzn): mapped onto [a MILP model](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_knapsack.mzn).
    * [`knapsack_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/knapsack.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_knapsack_reif.mzn).
* All different: `CP.AllDifferent`
    * [`all_different`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/all_different.mzn): mapped onto [a MILP-like model](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_all_different_int.mzn).
* All different except constants: `CP.AllDifferentExceptConstant` for one constant, not available for a set of constants
    * [`alldifferent_except_0`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/alldifferent_except_0.mzn) (one excluded value: 0) and [`alldifferent_except`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/alldifferent_except.mzn) (set of excluded values): either mapped [onto neq and disjunctions or onto GCC](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_alldifferent_except.mzn). The reified versions are only mapped [onto neq and disjunctions](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_alldifferent_except_reif.mzn).
