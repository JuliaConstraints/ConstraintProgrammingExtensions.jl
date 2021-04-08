Numberjack has a very similar goal to this project: a common modelling interface for many underlying solvers. List of supported global constraints: https://github.com/eomahony/Numberjack/blob/master/doc/source/globalcons.rst. List of other constraints: https://github.com/eomahony/Numberjack/blob/master/doc/source/constraints.rst

* `Numberjack.AllDiff`: `AllDifferent`
* `Numberjack.AllDiffExcept0`: `AllDifferentExceptConstant`
* `Numberjack.Sum`: MOI (linear expressions
* `Numberjack.Product`: MOI (quadratic expressions)
* `Numberjack.Gcc`: `Count`
* `Numberjack.LessLex`: `LexicographicallyLessThan`
* `Numberjack.LeqLex`: `LexicographicallyLessThan`
* `Numberjack.Disjunction`: `Disjunction`
* `Numberjack.Conjunction`: `Conjunction`
* `Numberjack.Max`: `MaximumAmong`
* `Numberjack.Min`: `MinimumAmong`
* `Numberjack.Element`: `Element`
* `Numberjack.Cardinality`: `Count`
* `Numberjack.Neg`: MOI (-)
* `Numberjack.Abs`: not yet (function)
* `Numberjack.And`: `Conjunction`
* `Numberjack.Or`: `Disjunction`
* `Numberjack.Eq`: `MOI.EqualTo`
* `Numberjack.Ne`: `DifferentFrom`
* `Numberjack.Lt`: `MOI.LessThan` and `Strictly`
* `Numberjack.Le`: `MOI.LessThan`
* `Numberjack.Gt`: `MOI.GreaterThan` and `Strictly`
* `Numberjack.Ge`: `MOI.GreaterThan`
* `Numberjack.Mul`: MOI (quadratic expression)
* `Numberjack.Div`: MOI (quadratic expression)
* `Numberjack.Mod`: not yet (function)
* `Numberjack.Table`: `Domain`
* `Numberjack.Precedence`: not yet (no notion of interval)
* `Numberjack.NoOverlap`: not yet (no notion of interval)
* `Numberjack.UnaryResource`: `CumulativeResource`
