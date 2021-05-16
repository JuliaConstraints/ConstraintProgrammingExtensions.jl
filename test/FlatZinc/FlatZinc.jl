@testset "FlatZinc" begin
    @testset "Model" begin
        @testset "Optimiser attributes" begin
            m = CP.FlatZinc.Optimizer()
            @test sprint(show, m) == "A FlatZinc (fzn) model"
        end

        @testset "Supported constraints" begin
            m = CP.FlatZinc.Optimizer()
            
            @test MOI.supports_constraint(m, MOI.SingleVariable, MOI.LessThan{Int})
            @test MOI.supports_constraint(
                m,
                MOI.SingleVariable,
                MOI.LessThan{Float64},
            )
            @test MOI.supports_constraint(
                m,
                MOI.SingleVariable,
                CP.Strictly{MOI.LessThan{Float64}},
            )
            @test MOI.supports_constraint(m, MOI.SingleVariable, CP.Domain{Int})
            @test MOI.supports_constraint(
                m,
                MOI.SingleVariable,
                MOI.Interval{Float64},
            )
            @test MOI.supports_constraint(m, MOI.VectorOfVariables, CP.Element{Int})
            @test MOI.supports_constraint(
                m,
                MOI.VectorOfVariables,
                CP.Element{Bool},
            )
            @test MOI.supports_constraint(
                m,
                MOI.VectorOfVariables,
                CP.Element{Float64},
            )
            @test MOI.supports_constraint(m, MOI.VectorOfVariables, CP.MaximumAmong)
            @test MOI.supports_constraint(m, MOI.VectorOfVariables, CP.MinimumAmong)
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Int},
                MOI.EqualTo{Int},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Int},
                MOI.LessThan{Int},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Int},
                CP.DifferentFrom{Int},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Float64},
                MOI.LessThan{Float64},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Float64},
                CP.Strictly{MOI.LessThan{Float64}},
            )
            @test MOI.supports_constraint(
                m,
                MOI.ScalarAffineFunction{Float64},
                CP.DifferentFrom{Float64},
            )
        end

        @testset "Supported constrained variable with $(S)" for S in [
            MOI.EqualTo{Float64},
            MOI.LessThan{Float64},
            MOI.GreaterThan{Float64},
            MOI.Interval{Float64},
            MOI.EqualTo{Int},
            MOI.LessThan{Int},
            MOI.GreaterThan{Int},
            MOI.Interval{Int},
            MOI.EqualTo{Bool},
            MOI.ZeroOne,
            MOI.Integer,
        ]
            m = CP.FlatZinc.Optimizer()
            @test MOI.supports_add_constrained_variables(m, S)
        end
    end

    @testset "Writing" begin
        @testset "Variables" begin
            ;
    
            a, a_gt0f = MOI.add_constrained_variable(m, MOI.GreaterThan(0.0))
            b, b_lt0f = MOI.add_constrained_variable(m, MOI.LessThan(0.0))
            c, c_eq0f = MOI.add_constrained_variable(m, MOI.EqualTo(0.0))
            d, d_intf = MOI.add_constrained_variable(m, MOI.Interval(0.0, 1.0))
            e, e_int = MOI.add_constrained_variable(m, MOI.Integer())
            f, f_int = MOI.add_constrained_variable(m, MOI.Integer())
            g, g_int = MOI.add_constrained_variable(m, MOI.Integer())
            h, h_eq0b = MOI.add_constrained_variable(m, MOI.EqualTo(false))
            i = MOI.add_variable(m)

            @test MOI.is_valid(m, a)
            @test MOI.is_valid(m, a_gt0f)
            @test MOI.is_valid(m, b)
            @test MOI.is_valid(m, b_lt0f)
            @test MOI.is_valid(m, c)
            @test MOI.is_valid(m, c_eq0f)
            @test MOI.is_valid(m, d)
            @test MOI.is_valid(m, d_intf)
            @test MOI.is_valid(m, e)
            @test MOI.is_valid(m, e_int)
            @test MOI.is_valid(m, f)
            @test MOI.is_valid(m, f_int)
            @test MOI.is_valid(m, g)
            @test MOI.is_valid(m, g_int)
            @test MOI.is_valid(m, h)
            @test MOI.is_valid(m, h_eq0b)
            @test MOI.is_valid(m, i)
        end

        @testset "Constraints: CP.MinimumAmong / CP.MaximumAmong" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            # Create variables.
            x, x_int = MOI.add_constrained_variables(m, [MOI.Integer() for _ in 1:5])
            
            @test !MOI.is_empty(m)
            for i in 1:5
                @test MOI.is_valid(m, x[i])
                @test MOI.is_valid(m, x_int[i])
            end
    
            # Don't set names to check whether they are made unique before 
            # generating the model.
            
            # Add constraints.
            c1 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables([x[1], x[2], x[3]]),
                CP.MaximumAmong(2),
            )
            c2 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables(x),
                CP.MinimumAmong(4),
            )
    
            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
    
            # Test some attributes for these constraints.
            @test MOI.get(m, MOI.ConstraintFunction(), c1) ==
                  MOI.VectorOfVariables([x[1], x[2], x[3]])
            @test MOI.get(m, MOI.ConstraintSet(), c1) == CP.MaximumAmong(2)
            @test MOI.get(
                m,
                MOI.ListOfConstraintIndices{
                    MOI.VectorOfVariables,
                    CP.Element{Int},
                }(),
            ) == MOI.ConstraintIndex[]
            @test MOI.get(
                m,
                MOI.ListOfConstraintIndices{
                    MOI.VectorOfVariables,
                    CP.MaximumAmong,
                }(),
            ) == [c1]
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 3
    
            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                var int: x2;
                var int: x3;
                var int: x4;
                var int: x5;
                
                
                
                constraint array_int_maximum(x1, [x2, x3]);
                constraint array_int_minimum(x1, [x2, x3, x4, x5]);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in x
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.Element" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            # Create variables.
            x, x_int = MOI.add_constrained_variables(m, [MOI.Integer() for _ in 1:2])
            y, y_bool = MOI.add_constrained_variables(m, [MOI.ZeroOne() for _ in 1:2])
            z = MOI.add_variables(m, 2)
            
            @test !MOI.is_empty(m)
            for i in 1:2
                @test MOI.is_valid(m, x[i])
                @test MOI.is_valid(m, x_int[i])
                @test MOI.is_valid(m, y[i])
                @test MOI.is_valid(m, y_bool[i])
                @test MOI.is_valid(m, z[i])
            end
    
            # Don't set names to check whether they are made unique before 
            # generating the model.
            
            # Add constraints.
            c1 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables(x),
                CP.Element([6, 5, 4]),
            )
            c2 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables(y),
                CP.Element([true, false]),
            )
            c3 = MOI.add_constraint(
                m,
                MOI.VectorOfVariables(z),
                CP.Element([1.0, 2.0]),
            )
            
            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
    
            # Test some attributes for these constraints.
            @test MOI.get(m, MOI.ConstraintFunction(), c1) ==
                  MOI.VectorOfVariables(x)
            @test MOI.get(m, MOI.ConstraintSet(), c1) == CP.Element([6, 5, 4])
            @test MOI.get(
                m,
                MOI.ListOfConstraintIndices{
                    MOI.VectorOfVariables,
                    CP.Element{Int},
                }(),
            ) == [c1]
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 5
    
            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                var int: x2;
                var bool: x3;
                var bool: x4;
                var float: x5;
                var float: x6;
                
                
                array [1..3] of int: ARRAY0 = [6, 5, 4];
                array [1..2] of bool: ARRAY1 = [true, false];
                array [1..2] of float: ARRAY2 = [1.0, 2.0];
                
                constraint array_int_element(x2, ARRAY0, x1);
                constraint array_bool_element(x4, ARRAY1, x3);
                constraint array_float_element(x6, ARRAY2, x5);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x..., y..., z...]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.DifferentFrom" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            # Create variables.
            x, x_int = MOI.add_constrained_variables(m, [MOI.Integer() for _ in 1:2])
            y = MOI.add_variables(m, 2)
            
            @test !MOI.is_empty(m)
            for i in 1:2
                @test MOI.is_valid(m, x[i])
                @test MOI.is_valid(m, x_int[i])
                @test MOI.is_valid(m, y[i])
            end
    
            # Don't set names to check whether they are made unique before 
            # generating the model.
            
            # Add constraints.
            c1 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], x), 0),
                CP.DifferentFrom(2),
            )
            c2 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(
                    MOI.ScalarAffineTerm.([1.0, 2.0], y),
                    0.0,
                ),
                CP.DifferentFrom(2.0),
            )

            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
    
            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 3
    
            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                var int: x2;
                var float: x3;
                var float: x4;
                
                

                constraint int_lin_ne([1, 1], [x1, x2], 2);
                constraint float_lin_ne([1, 2], [x3, x4], 2.0);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x..., y...]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end

        @testset "Constraints: CP.Domain" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            # Create variable.
            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_int)
    
            # Don't set names to check whether they are made unique before 
            # generating the model.
            
            # Create constraint.
            c = MOI.add_constraint(m, x, CP.Domain(Set([0, 1, 2])))
            @test MOI.is_valid(m, c)
            
            # Test some attributes for this constraint.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 2
    
            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;
                
                set of int: SET0 = {0, 2, 1};
                
                
                constraint set_in(x1, SET0);
                
                solve satisfy;
                """

            # Test that the name has been correctly transformed.
            xn = MOI.get(m, MOI.VariableName(), x)
            @test match(r"^x\d+$", xn) !== nothing
        end

        @testset "Constraints: CP.Interval" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            # Create variable.
            x = MOI.add_variable(m)
            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
    
            # Don't set names to check whether they are made unique before 
            # generating the model.

            # Create constraint.
            c = MOI.add_constraint(m, x, MOI.Interval(1.0, 2.0))
            @test MOI.is_valid(m, c)
            
            # Test some attributes for this constraint.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 1
    
            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var float: x1;
                
                
                
                constraint float_in(x1, 1.0, 2.0);
                
                solve satisfy;
                """

            # Test that the name has been correctly transformed.
            xn = MOI.get(m, MOI.VariableName(), x)
            @test match(r"^x\d+$", xn) !== nothing
        end

        @testset "Constraints: MOI.ScalarAffineFunction in MOI.EqualTo / MOI.LessThan / CP.Strictly{MOI.LessThan}" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            # Create variables.
            x, x_int = MOI.add_constrained_variables(m, [MOI.Integer() for _ in 1:2])
            y = MOI.add_variables(m, 2)
    
            @test !MOI.is_empty(m)
            for i in 1:2
                @test MOI.is_valid(m, x[i])
                @test MOI.is_valid(m, x_int[i])
                @test MOI.is_valid(m, y[i])
            end
    
            # Don't set names to check whether they are made unique before 
            # generating the model.
    
            # Add constraints.
            c1 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], x), 0),
                MOI.EqualTo(2),
            )
            c2 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], x), 0),
                MOI.LessThan(2),
            )
            c3 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(
                    MOI.ScalarAffineTerm.([1.0, 2.0], y),
                    0.0,
                ),
                MOI.EqualTo(2.0),
            )
            c4 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(
                    MOI.ScalarAffineTerm.([1.0, 2.0], y),
                    0.0,
                ),
                MOI.LessThan(2.0),
            )
            c5 = MOI.add_constraint(
                m,
                MOI.ScalarAffineFunction(
                    MOI.ScalarAffineTerm.([1.0, 2.0], y),
                    0.0,
                ),
                CP.Strictly(MOI.LessThan(2.0)),
            )
    
            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
            @test MOI.is_valid(m, c3)
            @test MOI.is_valid(m, c4)
            @test MOI.is_valid(m, c5)
    
            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 6
    
            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))
    
            @test fzn == """var int: x1;
                var int: x2;
                var float: x3;
                var float: x4;
                
                
                
                constraint int_lin_eq([1, 1], [x1, x2], 2);
                constraint int_lin_le([1, 1], [x1, x2], 2);
                constraint float_lin_eq([1, 2], [x3, x4], 2.0);
                constraint float_lin_le([1, 2], [x3, x4], 2.0);
                constraint float_lin_lt([1, 2], [x3, x4], 2.0);
                
                solve satisfy;
                """

            # Test that the names have been correctly transformed.
            for v in [x..., y...]
                vn = MOI.get(m, MOI.VariableName(), v)
                @test match(r"^x\d+$", vn) !== nothing
            end
        end
        
        @testset "Constraints: MOI.SingleVariable in MOI.LessThan / CP.Strictly{MOI.LessThan}" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            # Create variable.
            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
    
            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_int)
    
            # Don't set names to check whether they are made unique before 
            # generating the model.
    
            # Add constraints. 
            c1 = MOI.add_constraint(m, x, MOI.LessThan(2))
            c2 = MOI.add_constraint(m, x, CP.Strictly(MOI.LessThan(2)))
    
            @test MOI.is_valid(m, c1)
            @test MOI.is_valid(m, c2)
    
            # Test some attributes for these constraints.
            @test length(MOI.get(m, MOI.ListOfConstraints())) == 3
    
            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))
    
            @test fzn == "var int: x1;\n\n\n\nconstraint int_le(x1, 2);\nconstraint int_lt(x1, 2);\n\nsolve satisfy;\n"

            # Test that the name has been correctly transformed.
            xn = MOI.get(m, MOI.VariableName(), x)
            @test match(r"^x\d+$", xn) !== nothing
        end
        
        @testset "Name rewriting" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            # Create variables.
            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
            y, y_bool =
                MOI.add_constrained_variables(m, [MOI.ZeroOne() for _ in 1:5])
                
            # Set names. The name for x in invalid for FlatZinc, but not 
            # the ones for y.
            MOI.set(m, MOI.VariableName(), x, "_x")
            for i in 1:5
                MOI.set(m, MOI.VariableName(), y[i], "y_$(i)")
            end
    
            @test MOI.get(m, MOI.VariableName(), x) == "_x"
            for i in 1:5
                @test MOI.get(m, MOI.VariableName(), y[i]) == "y_$(i)"
            end
    
            # Generate the FZN file.
            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x_x;
                var bool: y_1;
                var bool: y_2;
                var bool: y_3;
                var bool: y_4;
                var bool: y_5;
                
                
                
                
                solve satisfy;
                """
    
            # Test that the names have been correctly transformed.
            @test MOI.get(m, MOI.VariableName(), x) == "x_x"
            for i in 1:5
                @test MOI.get(m, MOI.VariableName(), y[i]) == "y_$(i)"
            end
        end
        
        @testset "Maximising" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
    
            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_int)
    
            MOI.set(
                m,
                MOI.ObjectiveFunction{MOI.SingleVariable}(),
                MOI.SingleVariable(x),
            )
            
            MOI.set(m, MOI.ObjectiveSense(), MOI.MAX_SENSE)

            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;




            solve maximize x1;
            """
        end
        
        @testset "Minimising" begin
            m = CP.FlatZinc.Optimizer()
            @test MOI.is_empty(m)
    
            x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
    
            @test !MOI.is_empty(m)
            @test MOI.is_valid(m, x)
            @test MOI.is_valid(m, x_int)
    
            MOI.set(
                m,
                MOI.ObjectiveFunction{MOI.SingleVariable}(),
                MOI.SingleVariable(x),
            )
            
            MOI.set(m, MOI.ObjectiveSense(), MOI.MIN_SENSE)

            io = IOBuffer(truncate=true)
            write(io, m)
            fzn = String(take!(io))

            @test fzn == """var int: x1;




            solve minimize x1;
            """
        end
    end

    @testset "Reading" begin
        m = CP.FlatZinc.Optimizer()
        @test MOI.is_empty(m)

        @test_throws ErrorException read!(IOBuffer("42"), m)
    end
end
