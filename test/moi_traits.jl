@testset "Traits" begin
    @testset "is_binary" begin
        model = MOI.Utilities.Model{Float64}()
        x = MOI.add_variable(model)
        @test !CP.is_binary(model, x)
        @test !CP.is_binary(model, MOI.SingleVariable(x))

        c = MOI.add_constraint(model, x, MOI.ZeroOne())
        @test CP.is_binary(model, x)
        @test CP.is_binary(model, MOI.SingleVariable(x))
    end

    @testset "is_binary{$(T)}" for T in [Float64, Int]
        model = MOI.Utilities.Model{Float64}()
        x = MOI.add_variable(model)
        c = MOI.add_constraint(model, x, MOI.ZeroOne())

        aff = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T)], [x]),
            zero(T), 
        )
        aff2 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([2 * one(T)], [x]),
            zero(T), 
        )
        aff3 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T), zero(T)], [x, x]),
            zero(T), 
        )
        @test CP.is_binary(model, aff)
        @test !CP.is_binary(model, aff2)
        @test CP.is_binary(model, aff3)
    end

    @testset "is_integer" begin
        model = MOI.Utilities.Model{Float64}()
        x = MOI.add_variable(model)

        @test !CP.is_integer(model, x)
        @test !CP.is_integer(model, MOI.SingleVariable(x))

        c = MOI.add_constraint(model, x, MOI.Integer())
        @test CP.is_integer(model, x)
        @test CP.is_integer(model, MOI.SingleVariable(x))
    end

    @testset "has_lower_bound{Bool}" begin
        model = MOI.Utilities.Model{Bool}()

        x, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
        y, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())

        aff = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([true, false], [x, y]),
            false, 
        )
        aff2 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([true, true], [x, y]),
            false, 
        )

        # Booleans are implicitly bounded.
        @test CP.has_lower_bound(model, x)
        @test CP.has_lower_bound(model, MOI.SingleVariable(x))
        @test CP.has_lower_bound(model, aff)
        @test CP.has_lower_bound(model, aff2)
    end

    @testset "has_lower_bound{$(T)}" for T in [Float64, Int]
        model = MOI.Utilities.Model{T}()

        if T == Float64
            x = MOI.add_variable(model)
            y = MOI.add_variable(model)
        elseif T == Int
            x, _ = MOI.add_constrained_variable(model, MOI.Integer())
            y, _ = MOI.add_constrained_variable(model, MOI.Integer())
        else
            @assert false
        end

        aff = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T), zero(T)], [x, y]),
            zero(T), 
        )
        aff2 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T), one(T)], [x, y]),
            zero(T), 
        )

        # So far, variables are unbounded.
        @test !CP.has_lower_bound(model, x)
        @test !CP.has_lower_bound(model, MOI.SingleVariable(x))
        @test !CP.has_lower_bound(model, aff)
        @test !CP.has_lower_bound(model, aff2)

        # One variable has a lower bound. 
        MOI.add_constraint(model, x, MOI.GreaterThan(zero(T)))
        @test CP.has_lower_bound(model, x)
        @test CP.has_lower_bound(model, MOI.SingleVariable(x))
        @test CP.has_lower_bound(model, aff) # The other variable has a zero coefficient.
        @test !CP.has_lower_bound(model, aff2)

        # The other variable now has an upper bound: this should not have any 
        # impact on the results.
        MOI.add_constraint(model, y, MOI.LessThan(zero(T)))
        @test CP.has_lower_bound(model, x)
        @test CP.has_lower_bound(model, MOI.SingleVariable(x))
        @test CP.has_lower_bound(model, aff)
        @test !CP.has_lower_bound(model, aff2)
    end

    @testset "get_lower_bound{Bool}" begin
        model = MOI.Utilities.Model{Bool}()

        x, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
        y, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())

        aff = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([true, false], [x, y]),
            false, 
        )
        aff2 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([true, true], [x, y]),
            false, 
        )

        # Booleans are implicitly bounded.
        @test CP.get_lower_bound(model, x) == 0
        @test CP.get_lower_bound(model, MOI.SingleVariable(x)) == 0
        @test CP.get_lower_bound(model, aff) == 0
        @test CP.get_lower_bound(model, aff2) == 0
    end

    @testset "get_lower_bound{$(T)}" for T in [Float64, Int]
        model = MOI.Utilities.Model{T}()

        if T == Float64
            x = MOI.add_variable(model)
            y = MOI.add_variable(model)
        elseif T == Int
            x, _ = MOI.add_constrained_variable(model, MOI.Integer())
            y, _ = MOI.add_constrained_variable(model, MOI.Integer())
        else
            @assert false
        end

        aff = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T), zero(T)], [x, y]),
            zero(T), 
        )
        aff2 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T), one(T)], [x, y]),
            zero(T), 
        )

        # So far, variables are unbounded.
        @test CP.get_lower_bound(model, x) == typemin(T)
        @test CP.get_lower_bound(model, MOI.SingleVariable(x)) == typemin(T)
        @test CP.get_lower_bound(model, aff) == typemin(T)
        @test CP.get_lower_bound(model, aff2) == typemin(T)

        # One variable has a lower bound. 
        MOI.add_constraint(model, x, MOI.GreaterThan(zero(T)))
        @test CP.get_lower_bound(model, x) == zero(T)
        @test CP.get_lower_bound(model, MOI.SingleVariable(x)) == zero(T)
        @test CP.get_lower_bound(model, aff) == zero(T) # The other variable has a zero coefficient.
        @test CP.get_lower_bound(model, aff2) == typemin(T)

        # The other variable now has an upper bound: this should not have any 
        # impact on the results.
        MOI.add_constraint(model, y, MOI.LessThan(zero(T)))
        @test CP.get_lower_bound(model, x) == zero(T)
        @test CP.get_lower_bound(model, MOI.SingleVariable(x)) == zero(T)
        @test CP.get_lower_bound(model, aff) == zero(T)
        @test CP.get_lower_bound(model, aff2) == typemin(T)
    end

    @testset "has_upper_bound{Bool}" begin
        model = MOI.Utilities.Model{Bool}()

        x, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
        y, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())

        aff = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([true, false], [x, y]),
            false, 
        )
        aff2 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([true, true], [x, y]),
            false, 
        )

        # Booleans are implicitly bounded.
        @test CP.has_upper_bound(model, x)
        @test CP.has_upper_bound(model, MOI.SingleVariable(x))
        @test CP.has_upper_bound(model, aff)
        @test CP.has_upper_bound(model, aff2)
    end

    @testset "has_upper_bound{$(T)}" for T in [Float64, Int]
        model = MOI.Utilities.Model{T}()

        if T == Float64
            x = MOI.add_variable(model)
            y = MOI.add_variable(model)
        elseif T == Int
            x, _ = MOI.add_constrained_variable(model, MOI.Integer())
            y, _ = MOI.add_constrained_variable(model, MOI.Integer())
        else
            @assert false
        end

        aff = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T), zero(T)], [x, y]),
            zero(T), 
        )
        aff2 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T), one(T)], [x, y]),
            zero(T), 
        )

        # So far, variables are unbounded.
        @test !CP.has_upper_bound(model, x)
        @test !CP.has_upper_bound(model, MOI.SingleVariable(x))
        @test !CP.has_upper_bound(model, aff)
        @test !CP.has_upper_bound(model, aff2)

        # One variable has an upper bound. 
        MOI.add_constraint(model, x, MOI.LessThan(zero(T)))
        @test CP.has_upper_bound(model, x)
        @test CP.has_upper_bound(model, MOI.SingleVariable(x))
        @test CP.has_upper_bound(model, aff) # The other variable has a zero coefficient.
        @test !CP.has_upper_bound(model, aff2)

        # The other variable now has a lower bound: this should not have any 
        # impact on the results.
        MOI.add_constraint(model, y, MOI.GreaterThan(zero(T)))
        @test CP.has_upper_bound(model, x)
        @test CP.has_upper_bound(model, MOI.SingleVariable(x))
        @test CP.has_upper_bound(model, aff)
        @test !CP.has_upper_bound(model, aff2)
    end

    @testset "get_upper_bound{Bool}" begin
        model = MOI.Utilities.Model{Bool}()

        x, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
        y, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())

        aff = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([true, false], [x, y]),
            false, 
        )
        aff2 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([true, true], [x, y]),
            false, 
        )

        # Booleans are implicitly bounded.
        @test CP.get_upper_bound(model, x) == 1
        @test CP.get_upper_bound(model, MOI.SingleVariable(x)) == 1
        @test CP.get_upper_bound(model, aff) == 1
        @test CP.get_upper_bound(model, aff2) == 2 # TODO: is this wanted? a ScalarAffineFunction cannot really be a Boolean formula (1+1=1), so it makes sense.
    end

    @testset "get_upper_bound{$(T)}" for T in [Float64, Int]
        model = MOI.Utilities.Model{T}()

        if T == Float64
            x = MOI.add_variable(model)
            y = MOI.add_variable(model)
        elseif T == Int
            x, _ = MOI.add_constrained_variable(model, MOI.Integer())
            y, _ = MOI.add_constrained_variable(model, MOI.Integer())
        else
            @assert false
        end

        aff = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T), zero(T)], [x, y]),
            zero(T), 
        )
        aff2 = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([one(T), one(T)], [x, y]),
            zero(T), 
        )

        # So far, variables are unbounded.
        @test CP.get_upper_bound(model, x) == typemax(T)
        @test CP.get_upper_bound(model, MOI.SingleVariable(x)) == typemax(T)
        @test CP.get_upper_bound(model, aff) == typemax(T)
        @test CP.get_upper_bound(model, aff2) == typemax(T)

        # One variable has an upper bound. 
        MOI.add_constraint(model, x, MOI.LessThan(zero(T)))
        @test CP.get_upper_bound(model, x) == zero(T)
        @test CP.get_upper_bound(model, MOI.SingleVariable(x)) == zero(T)
        @test CP.get_upper_bound(model, aff) == zero(T) # The other variable has a zero coefficient.
        @test CP.get_upper_bound(model, aff2) == typemax(T)

        # The other variable now has a lower bound: this should not have any 
        # impact on the results.
        MOI.add_constraint(model, y, MOI.GreaterThan(zero(T)))
        @test CP.get_upper_bound(model, x) == zero(T)
        @test CP.get_upper_bound(model, MOI.SingleVariable(x)) == zero(T)
        @test CP.get_upper_bound(model, aff) == zero(T)
        @test CP.get_upper_bound(model, aff2) == typemax(T)
    end
end
