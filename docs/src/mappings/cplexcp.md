[Major constraints](https://www.ibm.com/docs/en/icos/20.1.0?topic=constraints-available-in-constraint-programming): 

* [`allDifferent`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplf_alldifferent.html): `AllDifferent`
* [`allMinDistance`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplf_allmindistance.html): `MinimumDistance`
* [`inverse`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplf_inverse.html): `Inverse`
* [`lex`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplf_lex.html): `LexicographicallyLessThan`, `LexicographicallyGreaterThan`
* [`pack`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplf_pack.html): `BinPacking`

Those for scheduling, not yet implemented: 

* [`endAtEnd`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_endAtEnd.html): 
* [`endAtStart`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_endAtStart.html): 
* [`endBeforeStart`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_endBeforeEnd.html): 
* [`endBeforeStart`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_endBeforeStart.html): 
* [`startAtEnd`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_startAtEnd.html): 
* [`startAtStart`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_startAtStart.html): 
* [`startBeforeEnd`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_startBeforeEnd.html): 
* [`startBeforeStart`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_startBeforeStart.html): 
* [`alternative`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_alternative.html): 
* [`span`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_span.html): 
* [`synchronize`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_synchronize.html): 
* [`presenceOf`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_presenceOf.html): 
* [`first`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_first.html): 
* [`last`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_last.html): 
* [`before`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_before.html): 
* [`prev`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplf_prev.html): 
* [`noOverlap`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_noOverlap.html): 
* [`<=` for cumulative resources](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_inferiorOrEqual.html): 
* [`alwaysIn`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_alwaysIn.html): 
* [`alwaysConstant`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_alwaysConstant.html): 
* [`alwaysEqual`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_alwaysEqual.html): 
* [`alwaysNoState`](https://www.ibm.com/docs/en/SSSA5P_20.1.0/ilog.odms.ide.help/OPL_Studio/opllang_quickref/topics/tlr_oplsch_alwaysNoState.html): 

Constraints removed/renamed between OPL 3 and OPL 6: 

* [`sequence`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_seq.html): what the heck!?
* [`circuit`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_circuit.html): `CP.Walk` (Eulerian circuit)
* [`alldifferent`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_alldiff.html): `CP.AllDifferent`
* [`atleast`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_atleast.html): `CP.Count` and `MOI.GreaterThan`
* [`atleastatmost`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_atleastmost.html): `CP.Count`, `MOI.GreaterThan`, and `MOI.LessThan`
* [`atmost`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_atmost.html): `CP.Count` and `MOI.LessThan`
* [`cardinality`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_card.html): `CP.GlobalCardinality`
* [`distribute`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_distrib.html): `CP.GlobalCardinality`
* [`forall`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xnoCP_constraint.html): use a loop over several constraints
* [`if`-`then`-`else`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_if.html): `IfThenElse`, `Implication` if no `else` clause
* [`not`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_not.html): `Negation`
* [`isInDomain`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_other.html): a function to check if a variable is assigned to a value in its domain, not a constraint
* [`predicate`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCP_constr_pred.html): `VectorDomain`

Functionalities from OPL 3 related to scheduling (not still implemented): 
* [transition times](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCPsched_lang_trans.html)
* [`Activity`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCPsched_lang_act.html): an interval
* [AlternativeResources](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCPsched_lang_alt.html): alternative intervals, only one of them is used for the activity to perform
* [`break`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCPsched_lang_breaks.html): variable interval intensity, a `stepFunction` applied onto an interval with the `intensity` keyword
* [cumulative resource](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCPsched_lang_cum.html): production and consumption of resourcesS
* [disjunctive resource](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCPsched_lang_disj.html): no overlap between intervals
* [`precedes`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCPsched_lang_prec.html): an interval ends before another starts
* [`StateResource`](https://lost-contact.mit.edu/afs/pdc.kth.se/roots/ilse/v0.7/pdc/vol/cplex/12.5/amd64_co5/doc/html/en-US/OPL_Studio/oplmigration/topics/opl_mig_prev_3x4x_3xCPsched_lang_state.html): state functions
