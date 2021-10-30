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
