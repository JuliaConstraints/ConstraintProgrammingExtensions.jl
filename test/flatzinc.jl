@testset "FlatZinc" begin
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
    
    @test MOI.is_valid(m, c1)
    @test MOI.is_valid(m, c2)
    @test MOI.is_valid(m, c3)

    # Generate the FZN file.
    io = IOBuffer(truncate=true)
    write(io, m)
    println(String(take!(io)))

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
