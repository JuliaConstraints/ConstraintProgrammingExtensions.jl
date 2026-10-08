@testset "Optimising" begin
    @testset "Parsing FlatZinc output format" begin
        @testset "one_solution.fzn" begin
            # Most simple output.
            out_string = "x = 10;\r\n\r\n----------\r\n==========\r\n"
            @test CP.FlatZinc._parse_to_assignments(out_string) == [
                Dict("x" => [10])
            ]
        end

        @testset "Infeasible" begin
            # Output for an infeasible model.
            out_string = "=====UNSATISFIABLE=====\r\n"
            @test CP.FlatZinc._parse_to_assignments(out_string) == []
        end
    
        @testset "basic.fzn" begin
            # Marker for the end of search: '=' ^ 10
            out_string = "x = 3;\r\n\r\n----------\r\n"
            @test CP.FlatZinc._parse_to_assignments(out_string) == [
                Dict("x" => [3])
            ]
        end
    
        @testset "basic.fzn with a float value" begin
            # Marker for the end of search: '=' ^ 10
            out_string = "x = 3.0;\r\n\r\n----------\r\n"
            @test CP.FlatZinc._parse_to_assignments(out_string) == [
                Dict("x" => [3.0])
            ]
        end
    
        @testset "several_solutions.fzn" begin
            # Several solutions (with CLI parameter -a)
            out_string = "xs = array1d(1..2, [2, 3]);\r\n\r\n----------\r\nxs = array1d(1..2, [1, 3]);\r\n\r\n----------\r\nxs = array1d(1..2, [1, 2]);\r\n\r\n----------\r\n==========\r\n"
            @test CP.FlatZinc._parse_to_assignments(out_string) == [
                Dict("xs" => [2, 3]),
                Dict("xs" => [1, 3]),
                Dict("xs" => [1, 2]),
            ]
        end
    
        @testset "puzzle.fzn" begin
            # 2D array
            out_string = "x = array2d(1..4, 1..4, [5, 1, 8, 8, 9, 3, 8, 6, 9, 7, 7, 8, 1, 7, 8, 9]);\r\n\r\n----------\r\n"
            @test CP.FlatZinc._parse_to_assignments(out_string) == [
                Dict("x" => [5, 1, 8, 8, 9, 3, 8, 6, 9, 7, 7, 8, 1, 7, 8, 9])
            ]
        end
    
        @testset "einstein.fzn" begin
            # Multiple variables
            out_string = "a = array1d(1..5, [5, 4, 3, 1, 2]);\r\nc = array1d(1..5, [3, 4, 5, 1, 2]);\r\nd = array1d(1..5, [2, 4, 3, 5, 1]);\r\nk = array1d(1..5, [3, 1, 2, 5, 4]);\r\ns = array1d(1..5, [3, 5, 2, 1, 4]);\r\n\r\n----------\r\n"
            @test CP.FlatZinc._parse_to_assignments(out_string) == [
                Dict(
                    "a" => [5, 4, 3, 1, 2], 
                    "c" => [3, 4, 5, 1, 2], 
                    "d" => [2, 4, 3, 5, 1],
                    "k" => [3, 1, 2, 5, 4], 
                    "s" => [3, 5, 2, 1, 4], 
                )
            ]
        end
    end
end

@testset "Optimizer attribute forwarding" begin
    model = CP.FlatZinc.Optimizer()
    variables = MOI.add_variables(model, 2)
    @test MOI.get(model, MOI.NumberOfVariables()) == 2
    @test MOI.get(model, MOI.ListOfVariableIndices()) == variables
    @test MOI.set(model, MOI.VariableName(), variables[1], "first") === nothing
    @test MOI.get(model, MOI.VariableName(), variables[1]) == "first"
    @test MOI.get(model, MOI.VariableIndex, "first") == variables[1]
    @test MOI.set(model, MOI.VariableName(), variables, ["a", "b"]) === nothing
    @test MOI.get(model, MOI.VariableName(), variables) == ["a", "b"]
    @test MOI.get(model, MOI.VariableName(), MOI.VariableIndex[]) == String[]
    @test_throws DimensionMismatch MOI.set(model, MOI.VariableName(), variables, ["a"])

    @test MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE) === nothing
    @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
    @test MOI.set(model, MOI.ObjectiveFunction{MOI.VariableIndex}(), variables[1]) === nothing
    @test MOI.get(model, MOI.ObjectiveFunction{MOI.VariableIndex}()) == variables[1]
    constraint = MOI.add_constraint(model, variables[1], MOI.LessThan(3))
    @test MOI.get(model, MOI.ConstraintFunction(), constraint) == variables[1]
    @test MOI.get(model, MOI.ConstraintSet(), constraint) == MOI.LessThan(3)
    @test MOI.get(model, MOI.ConstraintSet(), [constraint]) == [MOI.LessThan(3)]
    @test MOI.supports(model, MOI.ObjectiveFunction{MOI.VariableIndex}())
    @test MOI.supports(model, MOI.VariableName(), MOI.VariableIndex) ==
          MOI.supports(model.inner, MOI.VariableName(), MOI.VariableIndex)
    @test_throws MOI.UnsupportedAttribute MOI.supports(model, MOI.ConstraintName(), typeof(constraint))
    @test_throws MOI.UnsupportedAttribute MOI.supports(model.inner, MOI.ConstraintName(), typeof(constraint))
    @test_throws MOI.GetAttributeNotAllowed MOI.get(model, MOI.VariablePrimalStart(), variables[1])
    @test_throws MOI.UnsupportedAttribute MOI.set(model, MOI.VariablePrimalStart(), variables[1], 0)
    @test_throws MOI.GetAttributeNotAllowed MOI.get(model, MOI.ConstraintName(), constraint)
    @test_throws MOI.UnsupportedAttribute MOI.set(model, MOI.ConstraintName(), constraint, "row")
    MOI.set(model, MOI.TimeLimitSec(), 2.5)
    @test MOI.get(model, MOI.TimeLimitSec()) == 2.5
    MOI.set(model, MOI.Silent(), true)
    @test MOI.get(model, MOI.Silent())
    @test MOI.get(model, MOI.SolverName()) == "FlatZincWriter"

    # Keep dictionary behavior for missing and non-sequential indices; the
    # concrete field must not be replaced by a direct vector-index shortcut.
    @test_throws KeyError MOI.get(model, MOI.VariableName(), MOI.VariableIndex(99))
    gap = MOI.VariableIndex(5)
    model.inner.variable_info[gap] = CP.FlatZinc.VariableInfo(gap, "gap", MOI.Reals(1))
    @test MOI.get(model, MOI.VariableName(), gap) == "gap"
    @test MOI.get(model, MOI.VariableName(), variables) == ["a", "b"]
    MOI.set(model, MOI.VariableName(), gap, "renamed gap")
    @test MOI.get(model, MOI.VariableName(), gap) == "renamed gap"
    MOI.empty!(model)
    fresh = MOI.add_variable(model)
    MOI.set(model, MOI.VariableName(), fresh, "fresh")
    @test MOI.get(model, MOI.VariableName(), fresh) == "fresh"
end
