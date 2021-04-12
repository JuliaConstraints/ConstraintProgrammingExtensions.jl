@testset "FlatZinc" begin
    @testset "Writing constraints" begin
        m = CP.FlatZinc.Optimizer()
        @test sprint(show, m) == "A FlatZinc (fzn) model"
        @test MOI.is_empty(m)

        # Validity of constrained variables.
        for S in [
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
            @test MOI.supports_add_constrained_variables(m, S)
        end

        # Create variables.
        x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
        y, y_bool = MOI.add_constrained_variables(m, [MOI.ZeroOne() for _ in 1:5])
        
        a, a_gt0f = MOI.add_constrained_variable(m, MOI.GreaterThan(0.0))
        b, b_lt0f = MOI.add_constrained_variable(m, MOI.LessThan(0.0))
        c, c_eq0f = MOI.add_constrained_variable(m, MOI.EqualTo(0.0))
        d, d_intf = MOI.add_constrained_variable(m, MOI.Interval(0.0, 1.0))
        e, e_gt0i = MOI.add_constrained_variable(m, MOI.GreaterThan(0))
        f, f_lt0i = MOI.add_constrained_variable(m, MOI.LessThan(0))
        g, g_eq0i = MOI.add_constrained_variable(m, MOI.EqualTo(0))
        h, h_eq0b = MOI.add_constrained_variable(m, MOI.EqualTo(false))
        i = MOI.add_variable(m)

        @test ! MOI.is_empty(m)
        @test MOI.is_valid(m, x)
        @test MOI.is_valid(m, x_int)
        for i in 1:5
            @test MOI.is_valid(m, y[i])
            @test MOI.is_valid(m, y_bool[i])
        end
        @test MOI.is_valid(m, a)
        @test MOI.is_valid(m, a_gt0f)
        @test MOI.is_valid(m, b)
        @test MOI.is_valid(m, b_lt0f)
        @test MOI.is_valid(m, c)
        @test MOI.is_valid(m, c_eq0f)
        @test MOI.is_valid(m, d)
        @test MOI.is_valid(m, d_intf)
        @test MOI.is_valid(m, e)
        @test MOI.is_valid(m, e_gt0i)
        @test MOI.is_valid(m, f)
        @test MOI.is_valid(m, f_lt0i)
        @test MOI.is_valid(m, g)
        @test MOI.is_valid(m, g_eq0i)
        @test MOI.is_valid(m, h)
        @test MOI.is_valid(m, h_eq0b)
        @test MOI.is_valid(m, i)

        # Set names. Don't set them for all variables, to check whether names are 
        # made unique before generating the model.
        MOI.set(m, MOI.VariableName(), x, "_x") # Not valid in FlatZinc.
        for i in 1:5
            MOI.set(m, MOI.VariableName(), y[i], "y_$(i)")
        end

        @test MOI.get(m, MOI.VariableName(), x) == "_x"
        for i in 1:5
            @test MOI.get(m, MOI.VariableName(), y[i]) == "y_$(i)"
        end

        # Add constraints. The actual model does not make any sense, and is 
        # infeasible. This one is just for the sake of testing the output.
        c1 = MOI.add_constraint(m, MOI.VectorOfVariables([e, f]), CP.Element([6, 5, 4]))
        c2 = MOI.add_constraint(m, MOI.VectorOfVariables([e, f, g]), CP.MaximumAmong(2))
        c3 = MOI.add_constraint(m, MOI.VectorOfVariables([e, f, g]), CP.MinimumAmong(2))
        c4 = MOI.add_constraint(m, e, MOI.LessThan(2))
        c5 = MOI.add_constraint(m, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], [f, g]), 0), MOI.EqualTo(2))
        c6 = MOI.add_constraint(m, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], [f, g]), 0), MOI.LessThan(2))
        c7 = MOI.add_constraint(m, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1, 1], [f, g]), 0), CP.DifferentFrom(2))
        c8 = MOI.add_constraint(m, e, CP.Strictly(MOI.LessThan(2)))
        c9 = MOI.add_constraint(m, e, CP.Domain(Set([0, 1, 2])))
        c10 = MOI.add_constraint(m, MOI.VectorOfVariables([y[1], y[2]]), CP.Element([true, false]))
        c11 = MOI.add_constraint(m, MOI.VectorOfVariables([a, h]), CP.Element([1.0, 2.0]))
        c12 = MOI.add_constraint(m, a, MOI.Interval(1.0, 2.0))
        c13 = MOI.add_constraint(m, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 2.0], [a, b]), 0.0), MOI.EqualTo(2.0))
        c14 = MOI.add_constraint(m, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 2.0], [c, d]), 0.0), MOI.LessThan(2.0))
        c15 = MOI.add_constraint(m, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 2.0], [e, f]), 0.0), CP.Strictly(MOI.LessThan(2.0)))
        c15 = MOI.add_constraint(m, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 2.0], [g, h]), 0.0), CP.DifferentFrom(2.0))
        
        @test MOI.is_valid(m, c1)
        @test MOI.is_valid(m, c2)
        @test MOI.is_valid(m, c3)
        @test MOI.is_valid(m, c4)
        @test MOI.is_valid(m, c5)
        @test MOI.is_valid(m, c6)
        @test MOI.is_valid(m, c7)
        @test MOI.is_valid(m, c8)
        @test MOI.is_valid(m, c9)
        @test MOI.is_valid(m, c10)
        @test MOI.is_valid(m, c11)
        @test MOI.is_valid(m, c12)
        @test MOI.is_valid(m, c13)
        @test MOI.is_valid(m, c14)
        @test MOI.is_valid(m, c15)

        # Generate the FZN file.
        io = IOBuffer(truncate=true)
        write(io, m)
        fzn = String(take!(io))

        @test fzn == """var bool: x_x;
            var bool: y_1;
            var bool: y_2;
            var bool: y_3;
            var bool: y_4;
            var bool: y_5;
            var 0.0..1.7976931348623157e308: x7;
            var -1.7976931348623157e308..0.0: x8;
            var float: x9 = 0.0;
            var 0.0..1.0: x10;
            var 0..9223372036854775807: x11;
            var -9223372036854775808..0: x12;
            var int: x13 = 0;
            var bool: x14 = false;
            var float: x15;
            
            constraint array_int_element(x12, [6, 5, 4], x11);
            constraint array_int_maximum(x11, x12, x13);
            constraint array_int_minimum(x11, x12, x13);
            constraint int_le(x11, 2);
            constraint int_lin_eq([1, 1], [x12, x13], 2);
            constraint int_lin_le([1, 1], [x12, x13], 2);
            constraint int_lin_ne([1, 1], [x12, x13], 2);
            constraint int_lt(x11, 2);
            constraint set_in(x11, Set([0, 2, 1]));
            constraint array_bool_element(y_2, [1, 0], y_1);
            constraint array_float_element(x14, [1.0, 2.0], x7);
            constraint float_in(x7, 1.0, 2.0);
            constraint float_lin_eq([1, 2], [x7, x8], 2.0);
            constraint float_lin_le([1, 2], [x9, x10], 2.0);
            constraint float_lin_lt([1, 2], [x11, x12], 2.0);
            constraint float_lin_ne([1, 2], [x13, x14], 2.0);
            
            solve satisfy;
            """

        # Test that the names have been correctly transformed. (Redundant with the 
        # previous test, but will help with debugging.)
        @test MOI.get(m, MOI.VariableName(), x) == "x_x"
        for i in 1:5
            @test MOI.get(m, MOI.VariableName(), y[i]) == "y_$(i)"
        end
        for v in [a, b, c, d, e, f, g, h, i]
            vn = MOI.get(m, MOI.VariableName(), v)
            @test match(r"^x\d+$", vn) !== nothing
        end
    end

    @testset "Writing objectives" begin
        m = CP.FlatZinc.Optimizer()
        @test MOI.is_empty(m)

        x, x_int = MOI.add_constrained_variable(m, MOI.Integer())
        
        @test ! MOI.is_empty(m)
        @test MOI.is_valid(m, x)
        @test MOI.is_valid(m, x_int)
        
        MOI.set(m, MOI.ObjectiveFunction{MOI.SingleVariable}(), MOI.SingleVariable(x))

        # Minimise.
        MOI.set(m, MOI.ObjectiveSense(), MOI.MIN_SENSE)

        io = IOBuffer(truncate=true)
        write(io, m)
        fzn = String(take!(io))
        
        @test fzn == """var bool: x1;


        solve minimize x1;
        """

        # Maximise.
        MOI.set(m, MOI.ObjectiveSense(), MOI.MAX_SENSE)

        io = IOBuffer(truncate=true)
        write(io, m)
        fzn = String(take!(io))
        
        @test fzn == """var bool: x1;


        solve maximize x1;
        """
    end

    @testset "Reading" begin
        m = CP.FlatZinc.Optimizer()
        @test MOI.is_empty(m)
        
        @test_throws ErrorException read!(IOBuffer("42"), m)
    end
end
