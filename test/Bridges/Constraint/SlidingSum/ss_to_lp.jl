@testset "SlidingSum2LP: $(fct_type), $(array_size) items, $(slide_length) length, $(T)" for fct_type in ["vector of variables", "vector affine function"], array_size in [3, 4], slide_length in [1, 2], T in [Int, Float64]
    mock = MOIU.MockOptimizer(MILPModel{T}())
    model = COIB.SlidingSum2LP{T}(mock)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.ZeroOne)
    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.Integer)
    @test MOI.supports_constraint(
        model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorOfVariables,
        CP.SlidingSum{T},
    )
    
    if T == Int
        x_array, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:array_size])
    elseif T == Float64
        x_array = MOI.add_variables(model, array_size)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables(x_array)
    elseif fct_type == "vector affine function"
        MOIU.vectorize(x_array)
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.SlidingSum(T(2), T(5), slide_length, array_size)) 

    for i in 1:array_size
        @test MOI.is_valid(model, x_array[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.SlidingSum{T}}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.Count{MOI.EqualTo{T}}) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.ScalarAffineFunction{T}, MOI.Interval{T}),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{T}, MOI.Interval{T}}()) == array_size - slide_length

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{T}, MOI.Interval{T}}()) == bridge.cons
    end

    @testset "Constraints" begin
        @test length(bridge.cons) == array_size - slide_length

        for i in 1:(array_size - slide_length)
            @test MOI.is_valid(model, bridge.cons[i])
            @test MOI.get(model, MOI.ConstraintSet(), bridge.cons[i]) == MOI.Interval(T(2), T(5))

            f = MOI.get(model, MOI.ConstraintFunction(), bridge.cons[i])
            @test length(f.terms) == slide_length
            @test f.constant === zero(T)

            for j in 1:slide_length
                t = f.terms[j]
                @test t.coefficient === one(T)
                @test t.variable == x_array[i + j - 1]
            end
        end
    end
end
