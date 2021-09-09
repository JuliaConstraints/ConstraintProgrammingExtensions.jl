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