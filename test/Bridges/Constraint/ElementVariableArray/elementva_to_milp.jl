@testset "ElementVariableArray2MILP: $(fct_type), dimension $(dim), $(T)" for fct_type in ["vector of variables", "vector affine function"], dim in [2, 3], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.ElementVariableArray2MILP{T}(mock)

    @test MOI.supports_constraint(model, MOI.SingleVariable, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.ElementVariableArray,
    )

    x_index, _ = MOI.add_constrained_variable(model, MOI.Integer())
    if T == Int
        x_value, _ = MOI.add_constrained_variable(model, MOI.Integer())
        x_array, _ = MOI.add_constrained_variables(model, [MOI.Integer() for i in 1:dim])
    elseif T == Float64
        x_value = MOI.add_variable(model)
        x_array = MOI.add_variables(model, dim)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables([x_value, x_index, x_array...])
    elseif fct_type == "vector affine function"
        MOIU.vectorize(MOI.SingleVariable.([x_value, x_index, x_array...]))
    else
        @assert false
    end

    @test_throws AssertionError MOI.add_constraint(model, fct, CP.ElementVariableArray(dim))

    for i in 1:dim
        MOI.add_constraint(model, MOI.SingleVariable(x_array[i]), MOI.Interval(zero(T), one(T)))
    end

    c = MOI.add_constraint(model, fct, CP.ElementVariableArray(dim))

    @test MOI.is_valid(model, x_value)
    @test MOI.is_valid(model, x_index)
    for i in 1:dim
        @test MOI.is_valid(model, x_array[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.ElementVariableArray}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.ElementVariableArray) == typeof(bridge)
        if T == Int
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,), (MOI.Integer,)]
        elseif T == Float64
            @test MOIB.added_constrained_variable_types(typeof(bridge)) == [(MOI.ZeroOne,)]
        end
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
            (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
            (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 2 * dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.ZeroOne}()) == dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.SingleVariable, MOI.Integer}()) == ((T == Int) ? dim : 0)
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == 3
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == dim
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == dim

        @test MOI.get(bridge, MOI.ListOfVariableIndices()) == vcat(bridge.vars_unary, bridge.vars_product)
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.ZeroOne}()) == bridge.vars_unary_bin
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.SingleVariable, MOI.Integer}()) == bridge.vars_product_int
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}()) == [bridge.con_unary, bridge.con_choose_one, bridge.con_value]
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}()) == bridge.con_product_lt
        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}()) == bridge.con_product_gt
    end

    @testset "Set of binary variables" begin
        @test length(bridge.vars_unary) == dim
        @test length(bridge.vars_unary_bin) == dim

        for i in 1:dim
            @test MOI.is_valid(model, bridge.vars_unary[i])
            @test MOI.is_valid(model, bridge.vars_unary_bin[i])
            @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_unary_bin[i]) == MOI.SingleVariable(bridge.vars_unary[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_unary_bin[i]) == MOI.ZeroOne()
        end
    end

    @testset "Set of product variables" begin
        @test length(bridge.vars_product) == dim
        @test length(bridge.vars_product_int) == ((T == Int) ? dim : 0)

        for i in 1:dim
            @test MOI.is_valid(model, bridge.vars_product[i])

            if T == Int
                @test MOI.is_valid(model, bridge.vars_product_int[i])
                @test MOI.get(model, MOI.ConstraintFunction(), bridge.vars_product_int[i]) == MOI.SingleVariable(bridge.vars_product[i])
                @test MOI.get(model, MOI.ConstraintSet(), bridge.vars_product_int[i]) == MOI.Integer()
            end
        end
    end

    @testset "Unary decomposition of the index" begin
        @test MOI.is_valid(model, bridge.con_unary)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_unary)
        @test length(f.terms) == dim + 1
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_unary) == MOI.EqualTo(zero(T))

        t = f.terms[1]
        @test t.coefficient === -one(T)
        @test t.variabl == x_index

        for i in 1:dim
            t = f.terms[i + 1]
            @test t.coefficient === T(i)
            @test t.variabl == bridge.vars_unary[i]
        end
    end

    @testset "Unicity of the unary decomposition" begin
        @test MOI.is_valid(model, bridge.con_choose_one)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_choose_one)
        @test length(f.terms) == dim
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_choose_one) == MOI.EqualTo(one(T))

        for i in 1:dim
            t = f.terms[i]
            @test t.coefficient === one(T)
            @test t.variabl == bridge.vars_unary[i]
        end
    end

    @testset "Value at the index" begin
        @test MOI.is_valid(model, bridge.con_value)
        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_value)
        @test length(f.terms) == dim + 1
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_value) == MOI.EqualTo(zero(T))

        t = f.terms[1]
        @test t.coefficient === -one(T)
        @test t.variabl == x_value

        for i in 1:dim
            t = f.terms[i + 1]
            @test t.coefficient === one(T)
            @test t.variabl == bridge.vars_product[i]
        end
    end

    @testset "Constraining the product variables" begin
        @test length(bridge.con_product_lt) == dim
        @test length(bridge.con_product_gt) == dim

        for i in 1:dim
            @test MOI.is_valid(model, bridge.con_product_lt[i])
            flt = MOI.get(model, MOI.ConstraintFunction(), bridge.con_product_lt[i])
            @test length(flt.terms) == 2
            @test MOI.get(model, MOI.ConstraintSet(), bridge.con_product_lt[i]) == MOI.LessThan(zero(T))
            
            t1 = flt.terms[1]
            @test t1.coefficient === -one(T)
            @test t1.variabl == bridge.vars_unary[i]
            
            t2 = flt.terms[2]
            @test t2.coefficient === one(T)
            @test t2.variabl == bridge.vars_product[i]

            @test MOI.is_valid(model, bridge.con_product_gt[i])
            fgt = MOI.get(model, MOI.ConstraintFunction(), bridge.con_product_gt[i])
            @test length(fgt.terms) == 3
            @test MOI.get(model, MOI.ConstraintSet(), bridge.con_product_gt[i]) == MOI.GreaterThan(one(T))
            
            t1 = fgt.terms[1]
            @test t1.coefficient === -one(T)
            @test t1.variabl == x_array[i]
            
            t2 = fgt.terms[2]
            @test t2.coefficient === one(T)
            @test t2.variabl == bridge.vars_unary[i]
            
            t3 = fgt.terms[3]
            @test t3.coefficient === one(T)
            @test t3.variabl == bridge.vars_product[i]
        end
    end
end
