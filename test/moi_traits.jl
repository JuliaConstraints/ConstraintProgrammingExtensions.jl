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

    @testset "is_integer" begin
        model = MOI.Utilities.Model{Float64}()
        x = MOI.add_variable(model)

        @test !CP.is_integer(model, x)
        @test !CP.is_integer(model, MOI.SingleVariable(x))

        c = MOI.add_constraint(model, x, MOI.Integer())
        @test CP.is_integer(model, x)
        @test CP.is_integer(model, MOI.SingleVariable(x))
    end

    @testset "has_lower_bound" begin
        model = MOI.Utilities.Model{Float64}()
        x = MOI.add_variable(model)

        @test !CP.has_lower_bound(model, x)
        @test !CP.has_lower_bound(model, MOI.SingleVariable(x))

        c = MOI.add_constraint(model, x, MOI.GreaterThan(0.0))
        @test CP.has_lower_bound(model, x)
        @test CP.has_lower_bound(model, MOI.SingleVariable(x))
    end

    @testset "has_upper_bound" begin
        model = MOI.Utilities.Model{Float64}()
        x = MOI.add_variable(model)

        @test !CP.has_upper_bound(model, x)
        @test !CP.has_upper_bound(model, MOI.SingleVariable(x))

        c = MOI.add_constraint(model, x, MOI.LessThan(0.0))
        @test CP.has_upper_bound(model, x)
        @test CP.has_upper_bound(model, MOI.SingleVariable(x))
    end
end
