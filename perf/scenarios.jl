import ConstraintProgrammingExtensions as CP
import MathOptInterface as MOI

"Finite-domain bridge construction; preparation and projection checks are excluded from measurement."
function domain_bridge_case(parameters)
    rows = get(parameters, "rows", 32)
    dimension = get(parameters, "dimension", 1)
    rows > 0 && dimension > 0 || throw(ArgumentError("positive fixture sizes required"))
    prepare = () -> begin
        model = MOI.Utilities.Model{Float64}()
        variables = MOI.add_variables(model, dimension)
        if dimension == 1
            f = MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(2.0, only(variables))], 3.0)
            s = CP.Domain(Set(Float64.(1:rows)))
        else
            f = MOI.VectorAffineFunction([
                MOI.VectorAffineTerm(i, MOI.ScalarAffineTerm(2.0, variables[i]))
                for i in 1:dimension], fill(3.0, dimension))
            s = CP.VectorDomain(dimension, Set([Float64[j + i for i in 1:dimension] for j in 1:rows]))
        end
        (; model, variables, f, s)
    end
    operation = if dimension == 1
        state -> MOI.Bridges.Constraint.bridge_constraint(
            CP.Bridges.Domain2MILPBridge{Float64}, state.model, state.f, state.s)
    else
        state -> MOI.Bridges.Constraint.bridge_constraint(
            CP.Bridges.VectorDomain2MILPBridge{Float64}, state.model, state.f, state.s)
    end
    verify = (state, bridge) -> begin
        equations = MOI.get(bridge,
            MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{Float64},MOI.EqualTo{Float64}}())
        length(bridge.vars) == rows && length(equations) == dimension + 1 || return false
        domain = collect(state.s.values)
        assignment = zeros(MOI.get(state.model, MOI.NumberOfVariables()))
        for (j, value) in enumerate(domain)
            fill!(assignment, 0.0)
            assignment[bridge.vars[j].value] = 1.0
            for i in 1:dimension
                target = dimension == 1 ? value : value[i]
                assignment[state.variables[i].value] = (target - 3.0) / 2.0
            end
            for c in equations
                f = MOI.get(state.model, MOI.ConstraintFunction(), c)
                s = MOI.get(state.model, MOI.ConstraintSet(), c)
                f.constant + sum(t.coefficient * assignment[t.variable.value] for t in f.terms) == s.value || return false
            end
        end
        true
    end
    (; prepare, operation, verify)
end
