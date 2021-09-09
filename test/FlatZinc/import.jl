@testset "Reading" begin
    @testset "Item-splitting helper" begin
        io = IOBuffer(b"""var int: x1; 
            constraint int_eq(x1, 2);
            solve satisfy;""")

        @test CP.FlatZinc.get_fzn_item(io) == "var int: x1;"
        @test CP.FlatZinc.get_fzn_item(io) == "constraint int_eq(x1, 2);"
        @test CP.FlatZinc.get_fzn_item(io) == "solve satisfy;"
        @test CP.FlatZinc.get_fzn_item(io) == ""

        io = IOBuffer(b"""var int: x1; 
            var int: x2; % Comment at the end of a line
            
            % Comment feeling alone.
            
            constraint int_lin_eq([1, 1], [x1, x2], 2);
            
            solve satisfy;""")

        @test CP.FlatZinc.get_fzn_item(io) == "var int: x1;"
        @test CP.FlatZinc.get_fzn_item(io) == "var int: x2;"
        @test CP.FlatZinc.get_fzn_item(io) ==
              "constraint int_lin_eq([1, 1], [x1, x2], 2);"
        @test CP.FlatZinc.get_fzn_item(io) == "solve satisfy;"
        @test CP.FlatZinc.get_fzn_item(io) == ""

        io = IOBuffer(b"""% Comment at the beginning of a file
            
            % Comment feeling alone.
            
            solve satisfy;""")

        @test CP.FlatZinc.get_fzn_item(io) == "solve satisfy;"
        @test CP.FlatZinc.get_fzn_item(io) == ""
    end

    @testset "Parsing helpers" begin
        @testset "parse_array_type" begin
            @test_throws AssertionError CP.FlatZinc.parse_array_type("5")
            @test_throws AssertionError CP.FlatZinc.parse_array_type("2..5")
            @test_throws AssertionError CP.FlatZinc.parse_array_type(
                "[2..5]",
            )
            @test_throws AssertionError CP.FlatZinc.parse_array_type(
                "[2..5] ",
            )
            @test_throws AssertionError CP.FlatZinc.parse_array_type(
                " [2..5]",
            )
            @test_throws AssertionError CP.FlatZinc.parse_array_type(
                " [2..5] ",
            )

            @test CP.FlatZinc.parse_array_type("") === nothing
            @test CP.FlatZinc.parse_array_type("[1..5]") == 5
            @test CP.FlatZinc.parse_array_type("[  1  ..  5  ]") == 5
            @test CP.FlatZinc.parse_array_type("[1..9846515]") == 9846515
            @test CP.FlatZinc.parse_array_type(
                "[          1.. 9846515 ]",
            ) == 9846515
            @test CP.FlatZinc.parse_array_type("[1  ..9846515]") == 9846515
        end

        @testset "parse_range" begin
            @test_throws AssertionError CP.FlatZinc.parse_range("")
            @test_throws AssertionError CP.FlatZinc.parse_range("5")
            @test_throws ErrorException CP.FlatZinc.parse_range("[2..5]")
            @test_throws ErrorException CP.FlatZinc.parse_range("[2..5] ")
            @test_throws ErrorException CP.FlatZinc.parse_range(" [2..5]")
            @test_throws ErrorException CP.FlatZinc.parse_range(" [2..5] ")

            @test CP.FlatZinc.parse_range("1..5") ==
                  (CP.FlatZinc.FznInt, 1, 5)
            @test CP.FlatZinc.parse_range("1  ..  5") ==
                  (CP.FlatZinc.FznInt, 1, 5)
            @test CP.FlatZinc.parse_range("1..9846515") ==
                  (CP.FlatZinc.FznInt, 1, 9846515)
            @test CP.FlatZinc.parse_range("1.. 9846515") ==
                  (CP.FlatZinc.FznInt, 1, 9846515)

            @test CP.FlatZinc.parse_range("1..1.5") ==
                  (CP.FlatZinc.FznFloat, 1, 1.5)
            @test CP.FlatZinc.parse_range("1  ..  1.5") ==
                  (CP.FlatZinc.FznFloat, 1, 1.5)
            @test CP.FlatZinc.parse_range("1..9.846515") ==
                  (CP.FlatZinc.FznFloat, 1, 9.846515)
            @test CP.FlatZinc.parse_range("1.. 9.846515") ==
                  (CP.FlatZinc.FznFloat, 1, 9.846515)
        end

        @testset "parse_set" begin
            @test_throws AssertionError CP.FlatZinc.parse_set("")
            @test_throws AssertionError CP.FlatZinc.parse_set("5")
            @test_throws AssertionError CP.FlatZinc.parse_set("[2..5]")
            @test_throws AssertionError CP.FlatZinc.parse_set("{2, 5} ")
            @test_throws AssertionError CP.FlatZinc.parse_set(" {2, 5}")
            @test_throws AssertionError CP.FlatZinc.parse_set(" {2, 5} ")
            @test_throws AssertionError CP.FlatZinc.parse_set(" {a, b} ")

            @test CP.FlatZinc.parse_set("{}") == (CP.FlatZinc.FznInt, Int[])
            @test CP.FlatZinc.parse_set("{2}") == (CP.FlatZinc.FznInt, [2])
            @test CP.FlatZinc.parse_set("{2, 5}") ==
                  (CP.FlatZinc.FznInt, [2, 5])
            @test CP.FlatZinc.parse_set("{ 2 , 5 }") ==
                  (CP.FlatZinc.FznInt, [2, 5])
            @test CP.FlatZinc.parse_set("{1, 9846515}") ==
                  (CP.FlatZinc.FznInt, [1, 9846515])

            # No empty float set, impossible to distinguish from integers.
            @test CP.FlatZinc.parse_set("{2.0}") ==
                  (CP.FlatZinc.FznFloat, [2.0])
            @test CP.FlatZinc.parse_set("{2.0, 5.1}") ==
                  (CP.FlatZinc.FznFloat, [2.0, 5.1])
            @test CP.FlatZinc.parse_set("{ 2.0 , 5.1 }") ==
                  (CP.FlatZinc.FznFloat, [2.0, 5.1])
            @test CP.FlatZinc.parse_set("{1.0, 9.846515}") ==
                  (CP.FlatZinc.FznFloat, [1.0, 9.846515])
        end

        @testset "parse_variable_type" begin
            @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                "set of",
            )
            @test_throws ErrorException CP.FlatZinc.parse_variable_type(
                "set of [2..5]",
            )
            @test_throws ErrorException CP.FlatZinc.parse_variable_type(
                "set of [2..5",
            )
            @test_throws ErrorException CP.FlatZinc.parse_variable_type(
                "set of 2..5]",
            )
            @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                "set of {2, 5",
            )
            @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                "set of 2, 5}",
            )
            @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                "set of {2..5",
            )
            @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                "set of 2..5}",
            )
            @test_throws AssertionError CP.FlatZinc.parse_variable_type(
                "this is garbage",
            )

            @test CP.FlatZinc.parse_variable_type("bool") == (
                CP.FlatZinc.FznBool,
                CP.FlatZinc.FznScalar,
                nothing,
                nothing,
                nothing,
            )
            @test CP.FlatZinc.parse_variable_type("int") == (
                CP.FlatZinc.FznInt,
                CP.FlatZinc.FznScalar,
                nothing,
                nothing,
                nothing,
            )
            @test CP.FlatZinc.parse_variable_type("float") == (
                CP.FlatZinc.FznFloat,
                CP.FlatZinc.FznScalar,
                nothing,
                nothing,
                nothing,
            )
            @test CP.FlatZinc.parse_variable_type("set of int") == (
                CP.FlatZinc.FznInt,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                nothing,
            )

            @test CP.FlatZinc.parse_variable_type("set of {}") == (
                CP.FlatZinc.FznInt,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                Int[],
            )
            @test CP.FlatZinc.parse_variable_type("set of {2}") == (
                CP.FlatZinc.FznInt,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                [2],
            )
            @test CP.FlatZinc.parse_variable_type("set of {2, 5}") == (
                CP.FlatZinc.FznInt,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                [2, 5],
            )
            @test CP.FlatZinc.parse_variable_type("set of { 2 , 5 }") == (
                CP.FlatZinc.FznInt,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                [2, 5],
            )
            @test CP.FlatZinc.parse_variable_type("set of {1, 9846515}") ==
                  (
                CP.FlatZinc.FznInt,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                [1, 9846515],
            )

            # No empty float set, impossible to distinguish from integers.
            @test CP.FlatZinc.parse_variable_type("set of {2.0}") == (
                CP.FlatZinc.FznFloat,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                [2.0],
            )
            @test CP.FlatZinc.parse_variable_type("set of {2.0, 5.1}") == (
                CP.FlatZinc.FznFloat,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                [2.0, 5.1],
            )
            @test CP.FlatZinc.parse_variable_type("set of { 2.0 , 5.1 }") ==
                  (
                CP.FlatZinc.FznFloat,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                [2.0, 5.1],
            )
            @test CP.FlatZinc.parse_variable_type(
                "set of {1.0, 9.846515}",
            ) == (
                CP.FlatZinc.FznFloat,
                CP.FlatZinc.FznSet,
                nothing,
                nothing,
                [1.0, 9.846515],
            )

            @test CP.FlatZinc.parse_variable_type("set of 2..5") ==
                  (CP.FlatZinc.FznInt, CP.FlatZinc.FznSet, 2, 5, nothing)
        end

        @testset "parse_basic_expression" begin
            @test CP.FlatZinc.parse_basic_expression("true") == true
            @test CP.FlatZinc.parse_basic_expression("false") == false
            @test CP.FlatZinc.parse_basic_expression("1") == 1
            @test CP.FlatZinc.parse_basic_expression("1.0") == 1.0
            @test CP.FlatZinc.parse_basic_expression("x1") == "x1"
        end
    end

    @testset "Predicate section" begin
        m = CP.FlatZinc.Model()
        @test MOI.is_empty(m)
        @test_throws ErrorException CP.FlatZinc.parse_predicate!("", m)
    end

    @testset "Parameter section" begin
        m = CP.FlatZinc.Model()
        @test MOI.is_empty(m)
        @test_throws ErrorException CP.FlatZinc.parse_parameter!("", m)
    end

    @testset "Variable section" begin
        @testset "Split a variable entry" begin
            @test_throws AssertionError CP.FlatZinc.split_variable("")
            @test_throws AssertionError CP.FlatZinc.split_variable(
                "solve satisfy;",
            )

            # Vanilla declaration.
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable("var int: x1;")
            @test var_array == ""
            @test var_type == "int"
            @test var_name == "x1"
            @test var_annotations == [""]
            @test var_value == ""

            # With another type (still a string) and an *invalid* variable name.
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable("var bool: 5454;")
            @test var_array == ""
            @test var_type == "bool"
            @test var_name == "5454"
            @test var_annotations == [""]
            @test var_value == ""

            # With another type (range of integers).
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable("var 4..8: x1;")
            @test var_array == ""
            @test var_type == "4..8"
            @test var_name == "x1"
            @test var_annotations == [""]
            @test var_value == ""

            # With another type (range of floats).
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable("var 4.5..8.4: x1;")
            @test var_array == ""
            @test var_type == "4.5..8.4"
            @test var_name == "x1"
            @test var_annotations == [""]
            @test var_value == ""

            # With another type (set of floats, intension).
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable("var set of 4.5..8.4: x1;")
            @test var_array == ""
            @test var_type == "set of 4.5..8.4"
            @test var_name == "x1"
            @test var_annotations == [""]
            @test var_value == ""

            # With another type (set of floats, extension).
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable("var set of {4.5, 8.4}: x1;")
            @test var_array == ""
            @test var_type == "set of {4.5, 8.4}"
            @test var_name == "x1"
            @test var_annotations == [""]
            @test var_value == ""

            # With annotations.
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable(
                    "var int: x1 :: some_annotation;",
                )
            @test var_array == ""
            @test var_type == "int"
            @test var_name == "x1"
            @test var_annotations == ["some_annotation"]
            @test var_value == ""

            # With several annotations.
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable(
                    "var int: x1 :: some_annotation :: some_other_annotation;",
                )
            @test var_array == ""
            @test var_type == "int"
            @test var_name == "x1"
            @test var_annotations == ["some_annotation", "some_other_annotation"]
            @test var_value == ""

            # With value.
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable("var int: x1 = some_value;")
            @test var_array == ""
            @test var_type == "int"
            @test var_name == "x1"
            @test var_annotations == [""]
            @test var_value == "some_value"

            # With annotations and value.
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable(
                    "var int: x1 :: some_annotation = some_value;",
                )
            @test var_array == ""
            @test var_type == "int"
            @test var_name == "x1"
            @test var_annotations == ["some_annotation"]
            @test var_value == "some_value"

            # Array declaration.
            var_array, var_type, var_name, var_annotations, var_value =
                CP.FlatZinc.split_variable("array [1..5] of var int: x1;")
            @test var_array == "[1..5]"
            @test var_type == "int"
            @test var_name == "x1"
            @test var_annotations == [""]
            @test var_value == ""
        end

        @testset "Variable entry" begin
            m = CP.FlatZinc.Model()
            @test MOI.is_empty(m)

            moi_var_1 = CP.FlatZinc.parse_variable!("var bool: x1;", m)
            @test !MOI.is_empty(m)
            @test MOI.get(m, MOI.NumberOfVariables()) == 1
            @test MOI.get(
                m,
                MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}(),
            ) == 1
            @test length(m.variable_info) == 1
            @test m.variable_info[moi_var_1] !== nothing
            @test m.variable_info[moi_var_1].name == "x1"
            @test m.variable_info[moi_var_1].set == MOI.ZeroOne()
            @test length(m.constraint_info) == 1
            @test m.constraint_info[1].f == MOI.SingleVariable(moi_var_1)
            @test m.constraint_info[1].s == MOI.ZeroOne()
            @test m.constraint_info[1].output_as_part_of_variable

            @test_throws ErrorException CP.FlatZinc.parse_variable!(
                "var bool: x1;",
                m,
            )

            moi_var_2 = CP.FlatZinc.parse_variable!("var int: x2;", m)
            @test !MOI.is_empty(m)
            @test MOI.get(m, MOI.NumberOfVariables()) == 2
            @test MOI.get(
                m,
                MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}(),
            ) == 1
            @test length(m.variable_info) == 2
            @test m.variable_info[moi_var_2] !== nothing
            @test m.variable_info[moi_var_2].name == "x2"
            @test m.variable_info[moi_var_2].set == MOI.Integer()
            @test length(m.constraint_info) == 2
            @test m.constraint_info[2].f == MOI.SingleVariable(moi_var_2)
            @test m.constraint_info[2].s == MOI.Integer()
            @test m.constraint_info[2].output_as_part_of_variable

            moi_var_3 = CP.FlatZinc.parse_variable!("var float: x3;", m)
            @test !MOI.is_empty(m)
            @test MOI.get(m, MOI.NumberOfVariables()) == 3
            @test length(m.variable_info) == 3
            @test m.variable_info[moi_var_3] !== nothing
            @test m.variable_info[moi_var_3].name == "x3"
            @test m.variable_info[moi_var_3].set == MOI.Reals(1)
            @test length(m.constraint_info) == 2

            moi_var_4 = CP.FlatZinc.parse_variable!("var 0..7: x4;", m)
            @test !MOI.is_empty(m)
            @test MOI.get(m, MOI.NumberOfVariables()) == 4
            @test MOI.get(
                m,
                MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}(),
            ) == 2
            @test length(m.variable_info) == 4
            @test m.variable_info[moi_var_4] !== nothing
            @test m.variable_info[moi_var_4].name == "x4"
            @test m.variable_info[moi_var_4].set == MOI.Integer()
            @test length(m.constraint_info) == 4
            @test m.constraint_info[3].f == MOI.SingleVariable(moi_var_4)
            @test m.constraint_info[3].s == MOI.Integer()
            @test m.constraint_info[3].output_as_part_of_variable
            @test m.constraint_info[4].f == MOI.SingleVariable(moi_var_4)
            @test m.constraint_info[4].s == MOI.Interval(0, 7)
            @test !m.constraint_info[4].output_as_part_of_variable

            moi_var_5 = CP.FlatZinc.parse_variable!("var 0.0..7.0: x5;", m)
            @test !MOI.is_empty(m)
            @test MOI.get(m, MOI.NumberOfVariables()) == 5
            @test length(m.variable_info) == 5
            @test m.variable_info[moi_var_5] !== nothing
            @test m.variable_info[moi_var_5].name == "x5"
            @test m.variable_info[moi_var_5].set == MOI.Reals(1)
            @test length(m.constraint_info) == 5
            @test m.constraint_info[5].f == MOI.SingleVariable(moi_var_5)
            @test m.constraint_info[5].s == MOI.Interval(0.0, 7.0)
            @test !m.constraint_info[5].output_as_part_of_variable

            moi_var_6 = CP.FlatZinc.parse_variable!("var {0, 7}: x6;", m)
            @test !MOI.is_empty(m)
            @test MOI.get(m, MOI.NumberOfVariables()) == 6
            @test MOI.get(
                m,
                MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}(),
            ) == 3
            @test length(m.variable_info) == 6
            @test m.variable_info[moi_var_6] !== nothing
            @test m.variable_info[moi_var_6].name == "x6"
            @test m.variable_info[moi_var_6].set == MOI.Integer()
            @test length(m.constraint_info) == 7
            @test m.constraint_info[6].f == MOI.SingleVariable(moi_var_6)
            @test m.constraint_info[6].s == MOI.Integer()
            @test m.constraint_info[6].output_as_part_of_variable
            @test m.constraint_info[7].f == MOI.SingleVariable(moi_var_6)
            @test m.constraint_info[7].s == CP.Domain(Set([0, 7]))
            @test !m.constraint_info[7].output_as_part_of_variable

            moi_var_7 =
                CP.FlatZinc.parse_variable!("var {0.0, 7.0}: x7;", m)
            @test !MOI.is_empty(m)
            @test MOI.get(m, MOI.NumberOfVariables()) == 7
            @test length(m.variable_info) == 7
            @test m.variable_info[moi_var_7] !== nothing
            @test m.variable_info[moi_var_7].name == "x7"
            @test m.variable_info[moi_var_7].set == MOI.Reals(1)
            @test length(m.constraint_info) == 8
            @test m.constraint_info[8].f == MOI.SingleVariable(moi_var_7)
            @test m.constraint_info[8].s == CP.Domain(Set([0.0, 7.0]))
            @test !m.constraint_info[8].output_as_part_of_variable

            # TODO: implement this.
            @test_throws ErrorException CP.FlatZinc.parse_variable!(
                "array [1..5] of var int: x1;",
                m,
            )

            @test_throws ErrorException CP.FlatZinc.parse_variable!(
                "var set of int: x1;",
                m,
            )

            @test_logs (
                :warn,
                "Annotations are not supported and are currently ignored.",
            ) CP.FlatZinc.parse_variable!(
                "var {0.0, 7.0}: x42 :: SOME_ANNOTATION;",
                m,
            )
        end
    end

    @testset "Constraint section" begin
        @testset "Split a constraint entry" begin
            @test_throws AssertionError CP.FlatZinc.split_constraint("")
            @test_throws AssertionError CP.FlatZinc.split_constraint(
                "var int: x456389564;",
            ) # More than 10 characters to avoid the first assertion.

            @test CP.FlatZinc.split_constraint(
                "constraint int_le(0, x);",
            ) == ("int_le", "0, x", nothing)
            @test CP.FlatZinc.split_constraint(
                "constraint int_lin_eq([2, 3], [x, y], 10);",
            ) == ("int_lin_eq", "[2, 3], [x, y], 10", nothing)
            @test CP.FlatZinc.split_constraint(
                "constraint int_lin_eq([2, 3], [x, y], 10) :: domain;",
            ) == ("int_lin_eq", "[2, 3], [x, y], 10", "domain")
        end

        @testset "Split arguments" begin
            @test_throws AssertionError CP.FlatZinc.split_constraint_arguments(
                "",
            )

            @test CP.FlatZinc.split_constraint_arguments("1") == ["1"]
            @test CP.FlatZinc.split_constraint_arguments("1.1") == ["1.1"]
            @test CP.FlatZinc.split_constraint_arguments("x1") == ["x1"]
            @test CP.FlatZinc.split_constraint_arguments("true") == ["true"]
            @test CP.FlatZinc.split_constraint_arguments("false") ==
                  ["false"]

            @test CP.FlatZinc.split_constraint_arguments("1,") == ["1"]
            @test CP.FlatZinc.split_constraint_arguments("1.1,") == ["1.1"]
            @test CP.FlatZinc.split_constraint_arguments("x1,") == ["x1"]
            @test CP.FlatZinc.split_constraint_arguments("true,") ==
                  ["true"]
            @test CP.FlatZinc.split_constraint_arguments("false,") ==
                  ["false"]

            @test CP.FlatZinc.split_constraint_arguments("1, 1.1") ==
                  ["1", "1.1"]
            @test CP.FlatZinc.split_constraint_arguments("1.1, x1") ==
                  ["1.1", "x1"]
            @test CP.FlatZinc.split_constraint_arguments("x1, true") ==
                  ["x1", "true"]
            @test CP.FlatZinc.split_constraint_arguments("true, false") ==
                  ["true", "false"]
            @test CP.FlatZinc.split_constraint_arguments("false, 1") ==
                  ["false", "1"]
            @test CP.FlatZinc.split_constraint_arguments(
                "false  ,     1",
            ) == ["false", "1"]

            @test CP.FlatZinc.split_constraint_arguments("[1, 1.1]") ==
                  CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                "1",
                "1.1",
            ]]
            @test CP.FlatZinc.split_constraint_arguments("[1.1, x1]") ==
                  CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                "1.1",
                "x1",
            ]]
            @test CP.FlatZinc.split_constraint_arguments("[x1, true]") ==
                  CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                "x1",
                "true",
            ]]
            @test CP.FlatZinc.split_constraint_arguments("[true, false]") ==
                  CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                "true",
                "false",
            ]]
            @test CP.FlatZinc.split_constraint_arguments("[false, 1]") ==
                  CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                "false",
                "1",
            ]]

            @test CP.FlatZinc.split_constraint_arguments("[1, 1.1], x1") ==
                  CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                AbstractString["1", "1.1"],
                "x1",
            ]
            @test CP.FlatZinc.split_constraint_arguments(
                "[1.1, x1], true",
            ) == CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                AbstractString["1.1", "x1"],
                "true",
            ]
            @test CP.FlatZinc.split_constraint_arguments(
                "[x1, true], false",
            ) == CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                AbstractString["x1", "true"],
                "false",
            ]
            @test CP.FlatZinc.split_constraint_arguments(
                "[true, false], 1",
            ) == CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                AbstractString["true", "false"],
                "1",
            ]
            @test CP.FlatZinc.split_constraint_arguments(
                "[false, 1], 1.1",
            ) == CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                AbstractString["false", "1"],
                "1.1",
            ]
        end

        @testset "Parse arguments" begin
            @test CP.FlatZinc.parse_constraint_arguments(["1"]) == [1]
            @test CP.FlatZinc.parse_constraint_arguments(["1.1"]) == [1.1]
            @test CP.FlatZinc.parse_constraint_arguments(["x1"]) == ["x1"]
            @test CP.FlatZinc.parse_constraint_arguments(["true"]) == [true]
            @test CP.FlatZinc.parse_constraint_arguments(["false"]) ==
                  [false]

            @test CP.FlatZinc.parse_constraint_arguments(["1", "1.1"]) ==
                  [1, 1.1]
            @test CP.FlatZinc.parse_constraint_arguments(["1.1", "x1"]) ==
                  [1.1, "x1"]
            @test CP.FlatZinc.parse_constraint_arguments(["x1", "true"]) ==
                  ["x1", true]
            @test CP.FlatZinc.parse_constraint_arguments([
                "true",
                "false",
            ]) == [true, false]
            @test CP.FlatZinc.parse_constraint_arguments(["false", "1"]) ==
                  [false, 1]

            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "1",
                    "1.1",
                ]],
            ) == [[1, 1.1]]
            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "1.1",
                    "x1",
                ]],
            ) == [[1.1, "x1"]]
            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "x1",
                    "true",
                ]],
            ) == [["x1", true]]
            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "true",
                    "false",
                ]],
            ) == [[true, false]]
            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[AbstractString[
                    "false",
                    "1",
                ]],
            ) == [[false, 1]]

            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["1", "1.1"],
                    "x1",
                ],
            ) == [[1, 1.1], "x1"]
            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["1.1", "x1"],
                    "true",
                ],
            ) == [[1.1, "x1"], true]
            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["x1", "true"],
                    "false",
                ],
            ) == [["x1", true], false]
            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["true", "false"],
                    "1",
                ],
            ) == [[true, false], 1]
            @test CP.FlatZinc.parse_constraint_arguments(
                CP.FlatZinc.FZN_UNPARSED_ARGUMENT[
                    AbstractString["false", "1"],
                    "1.1",
                ],
            ) == [[false, 1], 1.1]
        end

        @testset "Parse constraint verbs from strings into enumeration" begin
            @test CP.FlatZinc.parse_constraint_verb("array_int_element") ==
                  CP.FlatZinc.FznArrayIntElement
            # Call it a day.
        end

        @testset "Array of mixed values to MOI variables" begin
            @testset "Variables and Booleans" begin
                m = CP.FlatZinc.Model()
                @test MOI.is_empty(m)

                x = CP.FlatZinc.parse_variable!("var bool: x;", m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 1

                a = CP.FlatZinc.array_mixed_var_bool_to_moi_var(
                    ["x", true],
                    m,
                )
                @test MOI.get(m, MOI.NumberOfVariables()) == 2
                @test length(a) == 2
                @test a[1] == x
                @test a[2] != x

                @test_throws ErrorException CP.FlatZinc.array_mixed_var_bool_to_moi_var(
                    ["x", MOI.Interval],
                    m,
                )
            end

            @testset "Variables and integers" begin
                m = CP.FlatZinc.Model()
                @test MOI.is_empty(m)

                x = CP.FlatZinc.parse_variable!("var int: x;", m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 1

                a = CP.FlatZinc.array_mixed_var_int_to_moi_var(["x", 1], m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 2
                @test length(a) == 2
                @test a[1] == x
                @test a[2] != x

                @test_throws ErrorException CP.FlatZinc.array_mixed_var_int_to_moi_var(
                    ["x", MOI.Interval],
                    m,
                )
            end

            @testset "Variables and floats" begin
                m = CP.FlatZinc.Model()
                @test MOI.is_empty(m)

                x = CP.FlatZinc.parse_variable!("var float: x;", m)
                @test MOI.get(m, MOI.NumberOfVariables()) == 1

                a = CP.FlatZinc.array_mixed_var_float_to_moi_var(
                    ["x", 1.0],
                    m,
                )
                @test MOI.get(m, MOI.NumberOfVariables()) == 2
                @test length(a) == 2
                @test a[1] == x
                @test a[2] != x

                @test_throws ErrorException CP.FlatZinc.array_mixed_var_float_to_moi_var(
                    ["x", MOI.Interval],
                    m,
                )
            end
        end

        @testset "Constraint entry" begin
            m = CP.FlatZinc.Model()
            @test MOI.is_empty(m)

            x1 = CP.FlatZinc.parse_variable!("var bool: x1;", m)
            x2 = CP.FlatZinc.parse_variable!("var bool: x2;", m)
            x3 = CP.FlatZinc.parse_variable!("var int: x3;", m)
            x4 = CP.FlatZinc.parse_variable!("var int: x4;", m)
            x5 = CP.FlatZinc.parse_variable!("var float: x5;", m)
            x6 = CP.FlatZinc.parse_variable!("var float: x6;", m)

            nc = 0

            # Missing semicolon (;).
            @test_throws AssertionError CP.FlatZinc.parse_constraint!(
                "constraint array_int_element(x2, [1, 2, 3], x2)",
                m,
            )

            CP.FlatZinc.parse_constraint!(
                "constraint array_int_element(x3, [1, 2, 3], x4);",
                m,
            )
            nc += 5
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f == MOI.VectorOfVariables([x4, x3])
            @test m.constraint_info[nc].s == CP.Element([1, 2, 3])

            CP.FlatZinc.parse_constraint!(
                "constraint array_int_maximum(x3, [1, 2, 3]);",
                m,
            )
            for i in 1:3
                nc += 1
                @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                @test m.constraint_info[nc].s == MOI.Integer()

                nc += 1
                @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                @test typeof(m.constraint_info[nc].s) <: MOI.EqualTo{Int}
            end
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[12].f) <: MOI.VectorOfVariables
            @test m.constraint_info[12].f.variables[1] == x3
            @test m.constraint_info[12].s == CP.MaximumAmong(3)

            CP.FlatZinc.parse_constraint!(
                "constraint array_int_maximum(x3, [x3, x4]);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[13].f.variables[1] == x3
            @test m.constraint_info[13].f.variables[2] == x3
            @test m.constraint_info[13].f.variables[3] == x4
            @test m.constraint_info[13].s == CP.MaximumAmong(2)

            CP.FlatZinc.parse_constraint!(
                "constraint array_int_minimum(x3, [1, 2, 3]);",
                m,
            )
            for i in 1:3
                nc += 1
                @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                @test m.constraint_info[nc].s == MOI.Integer()
                nc += 1

                @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                @test typeof(m.constraint_info[nc].s) <: MOI.EqualTo{Int}
            end
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
            @test m.constraint_info[nc].f.variables[1] == x3
            @test m.constraint_info[nc].s == CP.MinimumAmong(3)

            CP.FlatZinc.parse_constraint!(
                "constraint array_int_minimum(x3, [x3, x4]);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f.variables[1] == x3
            @test m.constraint_info[nc].f.variables[2] == x3
            @test m.constraint_info[nc].f.variables[3] == x4
            @test m.constraint_info[nc].s == CP.MinimumAmong(2)

            CP.FlatZinc.parse_constraint!(
                "constraint array_var_int_element(x3, [x1, x2, x3, x4], x4);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f ==
                  MOI.VectorOfVariables([x4, x3, x1, x2, x3, x4])
            @test m.constraint_info[nc].s == CP.ElementVariableArray(4)

            CP.FlatZinc.parse_constraint!("constraint int_eq(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == MOI.EqualTo(0)

            CP.FlatZinc.parse_constraint!("constraint int_eq(3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == MOI.EqualTo(3)

            CP.FlatZinc.parse_constraint!("constraint int_eq(x3, 4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == MOI.EqualTo(4)

            CP.FlatZinc.parse_constraint!(
                "constraint int_eq_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(0))

            CP.FlatZinc.parse_constraint!(
                "constraint int_eq_reif(3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(3))

            CP.FlatZinc.parse_constraint!(
                "constraint int_eq_reif(x3, 4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(4))

            CP.FlatZinc.parse_constraint!("constraint int_le(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == MOI.LessThan(0)

            CP.FlatZinc.parse_constraint!("constraint int_le(3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x4).
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === -1
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == MOI.LessThan(-3)

            CP.FlatZinc.parse_constraint!("constraint int_le(x3, 4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x3).
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == MOI.LessThan(4)

            CP.FlatZinc.parse_constraint!(
                "constraint int_le_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(0))

            CP.FlatZinc.parse_constraint!(
                "constraint int_le_reif(3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(-3))

            CP.FlatZinc.parse_constraint!(
                "constraint int_le_reif(x3, 4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(4))

            CP.FlatZinc.parse_constraint!(
                "constraint int_lin_eq([2, 3], [x1, x2], 5);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 2
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 3
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].s == MOI.EqualTo(5)

            CP.FlatZinc.parse_constraint!(
                "constraint int_lin_eq_reif([2, 3], [x1, x2], 5, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  2
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  3
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x2
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(5))

            CP.FlatZinc.parse_constraint!(
                "constraint int_lin_le([2, 3], [x1, x2], 5);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 2
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 3
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].s == MOI.LessThan(5)

            CP.FlatZinc.parse_constraint!(
                "constraint int_lin_le_reif([2, 3], [x1, x2], 5, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  2
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  3
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x2
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(5))

            CP.FlatZinc.parse_constraint!(
                "constraint int_lin_ne([2, 3], [x1, x2], 5);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 2
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 3
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].s == CP.DifferentFrom(5)

            CP.FlatZinc.parse_constraint!(
                "constraint int_lin_ne_reif([2, 3], [x1, x2], 5, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  2
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  3
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x2
            @test m.constraint_info[nc].s == CP.Reification(CP.DifferentFrom(5))

            CP.FlatZinc.parse_constraint!("constraint int_lt(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(0))

            CP.FlatZinc.parse_constraint!("constraint int_lt(3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x4).
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === -1
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(-3))

            CP.FlatZinc.parse_constraint!("constraint int_lt(x3, 4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x3).
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(4))

            CP.FlatZinc.parse_constraint!(
                "constraint int_lt_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(0)))

            CP.FlatZinc.parse_constraint!(
                "constraint int_lt_reif(3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(-3)))

            CP.FlatZinc.parse_constraint!(
                "constraint int_lt_reif(x3, 4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(4)))

            CP.FlatZinc.parse_constraint!(
                "constraint int_max(x1, x2, x3);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
            @test m.constraint_info[nc].f.variables[1] == x3
            @test m.constraint_info[nc].f.variables[2] == x1
            @test m.constraint_info[nc].f.variables[3] == x2
            @test m.constraint_info[nc].s == CP.MaximumAmong(2)

            CP.FlatZinc.parse_constraint!(
                "constraint int_min(x1, x2, x3);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
            @test m.constraint_info[nc].f.variables[1] == x3
            @test m.constraint_info[nc].f.variables[2] == x1
            @test m.constraint_info[nc].f.variables[3] == x2
            @test m.constraint_info[nc].s == CP.MinimumAmong(2)

            CP.FlatZinc.parse_constraint!("constraint int_ne(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == CP.DifferentFrom(0)

            CP.FlatZinc.parse_constraint!("constraint int_ne(3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == CP.DifferentFrom(3)

            CP.FlatZinc.parse_constraint!("constraint int_ne(x3, 4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == CP.DifferentFrom(4)

            CP.FlatZinc.parse_constraint!(
                "constraint int_ne_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(CP.DifferentFrom(0))

            CP.FlatZinc.parse_constraint!(
                "constraint int_ne_reif(3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(CP.DifferentFrom(3))

            CP.FlatZinc.parse_constraint!(
                "constraint int_ne_reif(x3, 4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s == CP.Reification(CP.DifferentFrom(4))

            CP.FlatZinc.parse_constraint!(
                "constraint int_plus(x1, x2, x3);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 1
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].f.terms[3].coefficient === -1
            @test m.constraint_info[nc].f.terms[3].variable_index == x3
            @test m.constraint_info[nc].s == MOI.EqualTo(0)

            CP.FlatZinc.parse_constraint!(
                "constraint array_bool_element(x3, [true, false, false], x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f == MOI.VectorOfVariables([x1, x3])
            @test m.constraint_info[nc].s ==
                  CP.Element([true, false, false])

            CP.FlatZinc.parse_constraint!(
                "constraint array_var_bool_element(x3, [x1, x2], x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f ==
                  MOI.VectorOfVariables([x1, x3, x1, x2])
            @test m.constraint_info[nc].s == CP.ElementVariableArray(2)

            CP.FlatZinc.parse_constraint!("constraint bool2int(x1, x3);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === -1
            @test m.constraint_info[nc].f.terms[2].variable_index == x3
            @test m.constraint_info[nc].s == MOI.EqualTo(0)

            CP.FlatZinc.parse_constraint!("constraint bool_eq(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == MOI.EqualTo(0)

            CP.FlatZinc.parse_constraint!("constraint bool_eq(3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == MOI.EqualTo(3)

            CP.FlatZinc.parse_constraint!("constraint bool_eq(x3, 4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == MOI.EqualTo(4)

            CP.FlatZinc.parse_constraint!(
                "constraint bool_eq_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(0))

            CP.FlatZinc.parse_constraint!(
                "constraint bool_eq_reif(3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(3))

            CP.FlatZinc.parse_constraint!(
                "constraint bool_eq_reif(x3, 4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(4))

            CP.FlatZinc.parse_constraint!("constraint bool_le(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == MOI.LessThan(0)

            CP.FlatZinc.parse_constraint!("constraint bool_le(3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x4).
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === -1
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == MOI.LessThan(-3)

            CP.FlatZinc.parse_constraint!("constraint bool_le(x3, 4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x3).
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == MOI.LessThan(4)

            CP.FlatZinc.parse_constraint!(
                "constraint bool_le_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(0))

            CP.FlatZinc.parse_constraint!(
                "constraint bool_le_reif(3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(-3))

            CP.FlatZinc.parse_constraint!(
                "constraint bool_le_reif(x3, 4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(4))

            CP.FlatZinc.parse_constraint!(
                "constraint bool_lin_eq([2, 3], [x1, x2], 5);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 2
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 3
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].s == MOI.EqualTo(5)

            CP.FlatZinc.parse_constraint!(
                "constraint bool_lin_le([2, 3], [x1, x2], 5);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 2
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 3
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].s == MOI.LessThan(5)

            CP.FlatZinc.parse_constraint!("constraint bool_lt(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int}
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(0))

            CP.FlatZinc.parse_constraint!("constraint bool_lt(3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x4).
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === -1
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(-3))

            CP.FlatZinc.parse_constraint!("constraint bool_lt(x3, 4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Int} # Equivalent to MOI.SingleVariable(x3).
            @test m.constraint_info[nc].f.constant === 0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(4))

            CP.FlatZinc.parse_constraint!(
                "constraint bool_lt_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(0)))

            CP.FlatZinc.parse_constraint!(
                "constraint bool_lt_reif(3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  -1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(-3)))

            CP.FlatZinc.parse_constraint!(
                "constraint bool_lt_reif(x3, 4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Int} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(4)))

            CP.FlatZinc.parse_constraint!(
                "constraint array_float_element(x3, [1.0, 2.0, 3.0], x5);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f == MOI.VectorOfVariables([x5, x3])
            @test m.constraint_info[nc].s == CP.Element([1.0, 2.0, 3.0])

            CP.FlatZinc.parse_constraint!(
                "constraint array_float_maximum(x5, [1.0, 2.0, 3.0]);",
                m,
            )
            for i in 1:3
                nc += 1
                @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                @test typeof(m.constraint_info[nc].s) <:
                      MOI.EqualTo{Float64}
            end
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
            @test m.constraint_info[nc].f.variables[1] == x5
            @test m.constraint_info[nc].s == CP.MaximumAmong(3)

            CP.FlatZinc.parse_constraint!(
                "constraint array_float_maximum(x5, [x5, x6]);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f.variables[1] == x5
            @test m.constraint_info[nc].f.variables[2] == x5
            @test m.constraint_info[nc].f.variables[3] == x6
            @test m.constraint_info[nc].s == CP.MaximumAmong(2)

            CP.FlatZinc.parse_constraint!(
                "constraint array_float_minimum(x5, [1.0, 2.0, 3.0]);",
                m,
            )
            for i in 1:3
                nc += 1
                @test typeof(m.constraint_info[nc].f) <: MOI.SingleVariable
                @test typeof(m.constraint_info[nc].s) <:
                      MOI.EqualTo{Float64}
            end
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
            @test m.constraint_info[nc].f.variables[1] == x5
            @test m.constraint_info[nc].s == CP.MinimumAmong(3)

            CP.FlatZinc.parse_constraint!(
                "constraint array_float_minimum(x5, [x5, x6]);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f.variables[1] == x5
            @test m.constraint_info[nc].f.variables[2] == x5
            @test m.constraint_info[nc].f.variables[3] == x6
            @test m.constraint_info[nc].s == CP.MinimumAmong(2)

            CP.FlatZinc.parse_constraint!(
                "constraint array_var_float_element(x3, [x1, x2, x3, x4, x5, x6], x6);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f ==
                  MOI.VectorOfVariables([x6, x3, x1, x2, x3, x4, x5, x6])
            @test m.constraint_info[nc].s == CP.ElementVariableArray(6)

            CP.FlatZinc.parse_constraint!("constraint float_eq(x5, x6);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64}
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x5
            @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x6
            @test m.constraint_info[nc].s == MOI.EqualTo(0.0)

            CP.FlatZinc.parse_constraint!("constraint float_eq(3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == MOI.EqualTo(3.0)

            CP.FlatZinc.parse_constraint!("constraint float_eq(x3, 4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == MOI.EqualTo(4.0)

            CP.FlatZinc.parse_constraint!(
                "constraint float_eq_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64}
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1.0
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(0.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_eq_reif(3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(3.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_eq_reif(x3, 4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0, 0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(4.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_in(x5, 1.0, 2.0);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f == MOI.SingleVariable(x5)
            @test m.constraint_info[nc].s == MOI.Interval(1.0, 2.0)

            CP.FlatZinc.parse_constraint!(
                "constraint float_in_reif(x5, 1.0, 2.0, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test m.constraint_info[nc].f == MOI.VectorOfVariables([x1, x5])
            @test m.constraint_info[nc].s ==
                  CP.Reification(MOI.Interval(1.0, 2.0))

            CP.FlatZinc.parse_constraint!("constraint float_le(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64}
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == MOI.LessThan(0.0)

            CP.FlatZinc.parse_constraint!("constraint float_le(3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64} # Equivalent to MOI.SingleVariable(x4).
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === -1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == MOI.LessThan(-3.0)

            CP.FlatZinc.parse_constraint!("constraint float_le(x3, 4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64} # Equivalent to MOI.SingleVariable(x3).
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == MOI.LessThan(4.0)

            CP.FlatZinc.parse_constraint!(
                "constraint float_le_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64}
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1.0
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(0.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_le_reif(3.0, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  -1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(-3.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_le_reif(x3, 4.0, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(4.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lin_eq([2.0, 3.0], [x1, x2], 5.0);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64}
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 2.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 3.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].s == MOI.EqualTo(5.0)

            CP.FlatZinc.parse_constraint!(
                "constraint float_lin_eq_reif([2.0, 3.0], [x1, x2], 5.0, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64}
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  2.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  3.0
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x2
            @test m.constraint_info[nc].s == CP.Reification(MOI.EqualTo(5.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lin_le([2.0, 3.0], [x1, x2], 5.0);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64}
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 2.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 3.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].s == MOI.LessThan(5.0)

            CP.FlatZinc.parse_constraint!(
                "constraint float_lin_le_reif([2.0, 3.0], [x1, x2], 5.0, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64}
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  2.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  3.0
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x2
            @test m.constraint_info[nc].s == CP.Reification(MOI.LessThan(5.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lin_lt([2.0, 3.0], [x1, x2], 5.0);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64}
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 2.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 3.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(5.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lin_lt_reif([2.0, 3.0], [x1, x2], 5.0, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64}
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  2.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  3.0
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x2
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(5.0)))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lin_ne([2.0, 3.0], [x1, x2], 5.0);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64}
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 2.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 3.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].s == CP.DifferentFrom(5.0)

            CP.FlatZinc.parse_constraint!(
                "constraint float_lin_ne_reif([2.0, 3.0], [x1, x2], 5.0, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64}
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  2.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  3.0
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x2
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.DifferentFrom(5.0))

            CP.FlatZinc.parse_constraint!("constraint float_lt(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64}
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(0.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lt(3.0, x4);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64} # Equivalent to MOI.SingleVariable(x4).
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === -1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(-3.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lt(x3, 4.0);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64} # Equivalent to MOI.SingleVariable(x3).
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == CP.Strictly(MOI.LessThan(4.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lt_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64}
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1.0
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(0.0)))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lt_reif(3.0, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  -1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(-3.0)))

            CP.FlatZinc.parse_constraint!(
                "constraint float_lt_reif(x3, 4.0, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.Strictly(MOI.LessThan(4.0)))

            CP.FlatZinc.parse_constraint!(
                "constraint float_max(x1, x2, x3);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
            @test m.constraint_info[nc].f.variables[1] == x3
            @test m.constraint_info[nc].f.variables[2] == x1
            @test m.constraint_info[nc].f.variables[3] == x2
            @test m.constraint_info[nc].s == CP.MaximumAmong(2)

            CP.FlatZinc.parse_constraint!(
                "constraint float_min(x1, x2, x3);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <: MOI.VectorOfVariables
            @test m.constraint_info[nc].f.variables[1] == x3
            @test m.constraint_info[nc].f.variables[2] == x1
            @test m.constraint_info[nc].f.variables[3] == x2
            @test m.constraint_info[nc].s == CP.MinimumAmong(2)

            CP.FlatZinc.parse_constraint!("constraint float_ne(x3, x4);", m)
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64}
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x4
            @test m.constraint_info[nc].s == CP.DifferentFrom(0.0)

            CP.FlatZinc.parse_constraint!(
                "constraint float_ne(3.0, x4);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x4)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x4
            @test m.constraint_info[nc].s == CP.DifferentFrom(3.0)

            CP.FlatZinc.parse_constraint!(
                "constraint float_ne(x3, 4.0);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction # Equivalent to: MOI.SingleVariable(x3)
            @test length(m.constraint_info[nc].f.terms) == 1
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].s == CP.DifferentFrom(4.0)

            CP.FlatZinc.parse_constraint!(
                "constraint float_ne_reif(x3, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64}
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].f.terms[3].output_index == 2
            @test m.constraint_info[nc].f.terms[3].scalar_term.coefficient ===
                  -1.0
            @test m.constraint_info[nc].f.terms[3].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.DifferentFrom(0.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_ne_reif(3.0, x4, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x4]).
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x4
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.DifferentFrom(3.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_ne_reif(x3, 4.0, x1);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.VectorAffineFunction{Float64} # Equivalent to MOI.VectorOfVariables([x1, x3]).
            @test m.constraint_info[nc].f.constants == [0.0, 0.0]
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].output_index == 1
            @test m.constraint_info[nc].f.terms[1].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[1].scalar_term.variable_index ==
                  x1
            @test m.constraint_info[nc].f.terms[2].output_index == 2
            @test m.constraint_info[nc].f.terms[2].scalar_term.coefficient ===
                  1.0
            @test m.constraint_info[nc].f.terms[2].scalar_term.variable_index ==
                  x3
            @test m.constraint_info[nc].s ==
                  CP.Reification(CP.DifferentFrom(4.0))

            CP.FlatZinc.parse_constraint!(
                "constraint float_plus(x1, x2, x3);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction
            @test length(m.constraint_info[nc].f.terms) == 3
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x1
            @test m.constraint_info[nc].f.terms[2].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x2
            @test m.constraint_info[nc].f.terms[3].coefficient === -1.0
            @test m.constraint_info[nc].f.terms[3].variable_index == x3
            @test m.constraint_info[nc].s == MOI.EqualTo(0.0)

            CP.FlatZinc.parse_constraint!(
                "constraint int2float(x3, x5);",
                m,
            )
            nc += 1
            @test length(m.constraint_info) == nc
            @test typeof(m.constraint_info[nc].f) <:
                  MOI.ScalarAffineFunction{Float64}
            @test m.constraint_info[nc].f.constant === 0.0
            @test length(m.constraint_info[nc].f.terms) == 2
            @test m.constraint_info[nc].f.terms[1].coefficient === 1.0
            @test m.constraint_info[nc].f.terms[1].variable_index == x3
            @test m.constraint_info[nc].f.terms[2].coefficient === -1.0
            @test m.constraint_info[nc].f.terms[2].variable_index == x5
            @test m.constraint_info[nc].s == MOI.EqualTo(0.0)
        end
    end

    @testset "Solve section" begin
        @testset "Split a solve entry" begin
            @test_throws AssertionError CP.FlatZinc.split_solve("")
            @test_throws AssertionError CP.FlatZinc.split_solve(
                "var int: x1;",
            )
            @test_throws AssertionError CP.FlatZinc.split_solve(
                "solve var int: x1;",
            )

            # Satisfy.
            obj_sense, obj_var = CP.FlatZinc.split_solve("solve satisfy;")
            @test obj_sense == CP.FlatZinc.FznSatisfy
            @test obj_var === nothing

            obj_sense, obj_var =
                CP.FlatZinc.split_solve("solve    satisfy   ;")
            @test obj_sense == CP.FlatZinc.FznSatisfy
            @test obj_var === nothing

            # Minimise.
            obj_sense, obj_var =
                CP.FlatZinc.split_solve("solve minimize x1;")
            @test obj_sense == CP.FlatZinc.FznMinimise
            @test obj_var == "x1"

            obj_sense, obj_var =
                CP.FlatZinc.split_solve("solve    minimize    x1   ;")
            @test obj_sense == CP.FlatZinc.FznMinimise
            @test obj_var == "x1"

            # Maximise.
            obj_sense, obj_var =
                CP.FlatZinc.split_solve("solve maximize x1;")
            @test obj_sense == CP.FlatZinc.FznMaximise
            @test obj_var == "x1"

            obj_sense, obj_var =
                CP.FlatZinc.split_solve("solve    maximize    x1   ;")
            @test obj_sense == CP.FlatZinc.FznMaximise
            @test obj_var == "x1"
        end

        @testset "Solve entry" begin
            m = CP.FlatZinc.Model()
            @test MOI.is_empty(m)
            moi_var = CP.FlatZinc.parse_variable!("var bool: x1;", m)
            @test MOI.get(m, MOI.ObjectiveSense()) == MOI.FEASIBILITY_SENSE

            CP.FlatZinc.parse_solve!("solve satisfy;", m)
            @test MOI.get(m, MOI.ObjectiveSense()) == MOI.FEASIBILITY_SENSE

            CP.FlatZinc.parse_solve!("solve minimize x1;", m)
            @test MOI.get(m, MOI.ObjectiveSense()) == MOI.MIN_SENSE
            @test MOI.get(m, MOI.ObjectiveFunction{MOI.SingleVariable}()) ==
                  MOI.SingleVariable(moi_var)

            CP.FlatZinc.parse_solve!("solve maximize x1;", m)
            @test MOI.get(m, MOI.ObjectiveSense()) == MOI.MAX_SENSE
            @test MOI.get(m, MOI.ObjectiveFunction{MOI.SingleVariable}()) ==
                  MOI.SingleVariable(moi_var)
        end
    end

    @testset "Base.read!" begin
        m = CP.FlatZinc.Model()
        @test MOI.is_empty(m)

        fzn = """var int: x1;
        constraint int_le(0, x1);
        solve maximize x1;"""

        read!(IOBuffer(fzn), m)

        @test !MOI.is_empty(m)
        @test MOI.get(m, MOI.NumberOfVariables()) == 1
        @test MOI.get(
            m,
            MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}(),
        ) == 1
        @test MOI.get(
            m,
            MOI.NumberOfConstraints{MOI.SingleVariable, MOI.LessThan}(),
        ) == 0
        @test MOI.get(
            m,
            MOI.NumberOfConstraints{
                MOI.ScalarAffineFunction{Int},
                MOI.LessThan,
            }(),
        ) == 0
        @test MOI.get(m, MOI.ObjectiveSense()) == MOI.MAX_SENSE

        @test_throws ErrorException read!(IOBuffer(fzn), m)
    end
end
