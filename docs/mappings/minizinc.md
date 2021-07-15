MiniZinc has a similar goal to this project: a common modelling interface for many underlying solvers. It is based on a similar concept to that of bridges, but with much less flexibility: each high-level constraint is mapped in a fixed way onto lower-level constraints.

* Basic CP constraints: 
    * Domain: 
        * Fixed: `CP.Domain`
        * Variable: `CP.Membership`
        * Multivalued: `CP.VectorDomain`
            * [`table`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/table.mzn)
    * All different: 
        * Base: `CP.AllDifferent`
            * [`all_different`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/all_different.mzn): mapped onto [a MILP-like model](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_all_different_int.mzn).
            * [`all_different_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/all_different.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_all_different_int_reif.mzn).
            * These constraints are available in two includes: `all_different.mzn` and `alldifferent.mzn`. 
        * All different except constants: `CP.AllDifferentExceptConstants`
            * [`alldifferent_except_0`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/alldifferent_except_0.mzn) (one excluded value: 0) and [`alldifferent_except`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/alldifferent_except.mzn) (set of excluded values): either mapped [onto neq and disjunctions or onto GCC](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_alldifferent_except.mzn). 
            * [`alldifferent_except_0_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/alldifferent_except_0.mzn) (one excluded value: 0) and [`alldifferent_except_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/alldifferent_except.mzn) (set of excluded values): the reified versions are only mapped [onto neq and disjunctions](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_alldifferent_except_reif.mzn).
        * With symmetry: `SymmetricAllDifferent`
            * [`symmetric_all_different`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/symmetric_all_different.mzn): [`all_different` and `inverse`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_symmetric_all_different.mzn)
            * [`symmetric_all_different`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/symmetric_all_different.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_symmetric_all_different_reif.mzn)
    * All equal: `CP.AllEqual`
        * [`all_equal`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/all_equal.mzn): mapped onto [a series of equalities](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_all_equal_int.mzn) if the dimension is at least two.
        * [`all_equal_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/all_equal.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_all_equal_int_reif.mzn).
    * Counting: `CP.Count`; variants of Minizinc's `count` are not equivalent to the parameters of `CP.Count`, Minizinc only matches `CP.Count{MOI.EqualTo}`
        * [`count_eq`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_eq.mzn): [direct comparison of each element](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_count_eq.mzn).
        * [`count_eq_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_eq.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_count_eq_reif.mzn).
        * [`count_neq`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_neq.mzn), [`count_lt`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_lt.mzn), [`count_le`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_le.mzn), [`count_gt`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_gt.mzn), [`count_ge`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_ge.mzn): [`count_eq` with a `!=`, `<`, `<=`, `>`, `>=` constraint](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_count_neq.mzn).
        * [`count_neq_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_neq.mzn), [`count_lt_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_lt.mzn), [`count_le_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_le.mzn), [`count_gt_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_gt.mzn), [`count_ge_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/count_ge.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_count_neq_reif.mzn).
        * [`exactly`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/exactly.mzn): [simple variation of `count`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_exactly_int.mzn), not directly mapped in this package.
        * [`global_cardinality`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/global_cardinality.mzn): [simple variation of `count`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_global_cardinality.mzn).
        * [`global_cardinality_fn`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/global_cardinality_fn.mzn): function, [simple variation of `count`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/global_cardinality_fn.mzn).
        * [`global_cardinality_closed`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/global_cardinality_closed.mzn): [simple variation of `count` with domains](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_global_cardinality_closed.mzn).
        * [`global_cardinality_closed_fn`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/global_cardinality_closed_fn.mzn): function, [simple variation of `count`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/global_cardinality_closed_fn.mzn).
        * [`nvalue`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/nvalue.mzn): [simple variation of reified comparisons](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_nvalue.mzn).
        * [`nvalue_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/nvalue.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_nvalue_reif.mzn).
        * [`nvalue_fn`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/nvalue_fn.mzn): function.
    * Inversion: `CP.Inverse`
        * [`inverse`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/inverse.mzn): [index computations](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_inverse.mzn).
        * [`inverse_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/inverse.mzn): similar, [wih an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_inverse_reif.mzn).
        * Also available [as a function](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/inverse_fn.mzn).
        * [`inverse_in_range`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/inverse_in_range.mzn): [?](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_inverse_in_range.mzn).
    * Sliding sum: `CP.SlidingSum`
        * [`sliding_sum`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/sliding_sum.mzn): [quite complex mapping](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_sliding_sum.mzn)
        * [`sliding_sum_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/sliding_sum.mzn): similar, [with an equivalence](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_sliding_sum_reif.mzn)
* Combinatorial sets:
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
* Sorting: 
    * Maximum/minimum: `CP.MaximumAmong` and `CP.MinimumAmong`
        * [`maximum`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/maximum.mzn): built-in, [except for linear solvers](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/linear/redefinitions.mzn)
        * [`minimum`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/minimum.mzn): built-in, [except for linear solvers](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/linear/redefinitions.mzn)
        * No reification available.
    * Argument maximum/minimum: `CP.ArgumentMaximumAmong` and `CP.MinimumAmong`
        * [`arg_max`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/arg_max.mzn): [complex mapping](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_arg_max_int.mzn) from [The ARGMAX Constraint, CP2020](https://research.monash.edu/en/publications/the-argmax-constraint).
        * [`arg_min`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/arg_min.mzn): [complex mapping](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_arg_min_int.mzn) from [The ARGMAX Constraint, CP2020](https://research.monash.edu/en/publications/the-argmax-constraint).
        * No reification available.
    * Permutation to sort: `CP.SortPermutation`
        * [`arg_sort`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/arg_sort.mzn): [alldifferent and array indexing](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_arg_sort_float.mzn).
        * No reification available.
    * Sort: `CP.Sort`
        * [`sort`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/sort.mzn): [alldifferent, increasing and array indexing](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_sort.mzn), highly similar to `arg_sort`.
        * [`sort_reif`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/sort.mzn): [equivalence, indicating whether a given array is a sorted copy of another](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_sort_reif.mzn).
        * [`sort_fn`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/sort_fn.mzn): returns the sorted array, based on `sort`.
    * Increasing and decreasing: `CP.Increasing`, `CP.Decreasing`, and `CP.Strictly`
        * [`increasing`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/increasing.mzn): [sequence of inequalities](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_increasing_int.mzn).
        * [`decreasing`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/decreasing.mzn): [sequence of inequalities](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_decreasing_int.mzn).
        * [`strictly_increasing`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/strictly_increasing.mzn): [sequence of strict inequalities](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_increasing_int.mzn).
        * [`strictly_decreasing`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/strictly_ecreasing.mzn): [sequence of strict inequalities](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_decreasing_int.mzn).
        * No reification available.
    * Lexicographic sorting: `CP.LexicographicallyLessThan`, `CP.LexicographicallyGreaterThan`, `CP.DoublyLexicographicallyLessThan`, and `CP.DoublyLexicographicallyGreaterThan`
        * [`lex_greater`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/lex_greater.mzn), [`lex_less`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/lex_less.mzn), [`lex_greatereq`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/lex_greatereq.mzn), [`lex_lesseq`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/lex_lesseq.mzn): [implemented using the definition of lexicographic sorting](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_lex_less_int.mzn).
        * [`lex_chain_greater`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/lex_chain_greater.mzn), [`lex_chain_less`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/lex_chain_less.mzn), [`lex_chain_greatereq`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/lex_chain_greatereq.mzn), [`lex_chain_lesseq`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/lex_chain_lesseq.mzn): lexicographic sort of a matrix of vectors, [mapped to lexicographic relation between two arrays](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_lex_chain_less_int.mzn).
        * [`lex2`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/lex2.mzn): in a matrix, have both rows and columns lexicographically sorted, [mapped to two chains](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_lex2.mzn).
        * [`strict_lex2`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/strict_lex2.mzn): in a matrix, have both rows and columns strictly lexicographically sorted, [mapped to two chains](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_strict_lex2.mzn).
        * Reifications are available.
* Scheduling: 
    * Rectangle overlapping: `CP.NonOverlappingOrthotopes` and `CP.ConditionallyNonOverlappingOrthotopes`
        * [`diffn`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/diffn.mzn): [mapped to a disjunction of linear inequalities](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_diffn.mzn).
        * [`diffn_k`](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/diffn.mzn): generalisation to `k` dimensions.
        * No reification available, but [a similar mapping is available](https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/std/fzn_diffn_reif.mzn).
