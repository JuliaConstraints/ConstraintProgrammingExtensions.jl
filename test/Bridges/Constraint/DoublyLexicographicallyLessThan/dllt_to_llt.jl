@testset "DoublyLexicographicallyLessThan2LexicographicallyLessThan: $(fct_type), $(x_size) × $(y_size), $(T)" for fct_type in ["vector of variables", "vector affine function"], x_size in [2, 4], y_size in [2, 4], T in [Int, Float64]
    mock = MOIU.MockOptimizer(LexicographicallyLessThanModel{T}())
    model = COIB.DoublyLexicographicallyLessThan2LexicographicallyLessThan{T}(mock)

    @test MOI.supports_constraint(model, MOI.VariableIndex, MOI.ZeroOne)
    @test MOI.supports_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.LexicographicallyLessThan,
    )
    @test MOIB.supports_bridging_constraint(
        model,
        MOI.VectorAffineFunction{T},
        CP.DoublyLexicographicallyLessThan,
    )
    
    if T == Int
        x_array, _ = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:(x_size * y_size)])
    elseif T == Float64
        x_array = MOI.add_variables(model, x_size * y_size)
    end

    fct = if fct_type == "vector of variables"
        MOI.VectorOfVariables(x_array)
    elseif fct_type == "vector affine function"
        MOIU.vectorize(x_array)
    else
        @assert false
    end
    c = MOI.add_constraint(model, fct, CP.DoublyLexicographicallyLessThan(x_size, y_size))

    for i in 1:(x_size * y_size)
        @test MOI.is_valid(model, x_array[i])
    end
    @test MOI.is_valid(model, c)

    bridge = MOIBC.bridges(model)[MOI.ConstraintIndex{MOI.VectorOfVariables, CP.DoublyLexicographicallyLessThan}(-1)]

    @testset "Bridge properties" begin
        @test MOIBC.concrete_bridge_type(typeof(bridge), MOI.VectorOfVariables, CP.DoublyLexicographicallyLessThan) == typeof(bridge)
        @test MOIB.added_constrained_variable_types(typeof(bridge)) == Tuple{Type}[]
        @test MOIB.added_constraint_types(typeof(bridge)) == [
            (MOI.VectorAffineFunction{T}, CP.LexicographicallyLessThan),
        ]

        @test MOI.get(bridge, MOI.NumberOfVariables()) == 0
        @test MOI.get(bridge, MOI.NumberOfConstraints{MOI.VectorAffineFunction{T}, CP.LexicographicallyLessThan}()) == 2

        @test MOI.get(bridge, MOI.ListOfConstraintIndices{MOI.VectorAffineFunction{T}, CP.LexicographicallyLessThan}()) == [bridge.con, bridge.con_transposed]
    end

    @testset "Column constraint" begin
        @test MOI.is_valid(model, bridge.con)
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con) == CP.LexicographicallyLessThan(x_size, y_size)

        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con)
        @test length(f.terms) == x_size * y_size
        @test f.constants == zeros(T, x_size * y_size)

        idx = LinearIndices((x_size, y_size))
        for i in 1:x_size
            for j in 1:y_size
                t = f.terms[idx[i, j]]
                @test t.output_index == idx[i, j]
                @test t.scalar_term.coefficient === one(T)
                @test t.scalar_term.variable === x_array[idx[i, j]]
            end
        end
    end

    @testset "Row constraint (transposed)" begin
        @test MOI.is_valid(model, bridge.con_transposed)
        @test MOI.get(model, MOI.ConstraintSet(), bridge.con_transposed) == CP.LexicographicallyLessThan(y_size, x_size)

        f = MOI.get(model, MOI.ConstraintFunction(), bridge.con_transposed)
        @test length(f.terms) == x_size * y_size
        @test f.constants == zeros(T, x_size * y_size)

        idx = LinearIndices((y_size, x_size))
        for i in 1:x_size
            for j in 1:y_size
                t = f.terms[idx[j, i]]
                @test t.output_index == idx[j, i]
                @test t.scalar_term.coefficient === one(T)
                @test t.scalar_term.variable === x_array[idx[j, i]]
            end
        end
    end
end
    