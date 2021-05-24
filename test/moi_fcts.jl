@testset "Nonlinear functions" begin
    @testset "Copy" begin
        @testset "NonlinearScalarAffineFunction" begin
            x = MOI.VariableIndex(1)
            y = MOI.VariableIndex(2)

            t1 = CP.NonlinearScalarAffineTerm(MOI.SingleVariable(x))
            t2 = CP.NonlinearScalarAffineTerm(MOI.SingleVariable(y))
            f = CP.NonlinearScalarAffineFunction([t1, t2])

            f_copy = copy(f)
            f_copy.terms[2] = CP.NonlinearScalarAffineTerm(MOI.SingleVariable(x))
            @test f != f_copy
            @test f.terms[2].expr == MOI.SingleVariable(y)
        end

        @testset "NonlinearScalarProductFunction" begin
            x = MOI.VariableIndex(1)
            y = MOI.VariableIndex(2)

            f1 = CP.NonlinearScalarFactor(MOI.SingleVariable(x))
            f2 = CP.NonlinearScalarFactor(MOI.SingleVariable(y))
            f = CP.NonlinearScalarProductFunction([f1, f2])

            f_copy = copy(f)
            f_copy.factors[2] = CP.NonlinearScalarFactor(MOI.SingleVariable(x))
            @test f != f_copy
            @test f.factors[2].expr == MOI.SingleVariable(y)
        end

        @testset "$F" for F in [CP.SquareRootFunction, CP.InverseFunction]
            x = MOI.VariableIndex(1)
            y = MOI.VariableIndex(2)

            f1 = CP.NonlinearScalarFactor(MOI.SingleVariable(x))
            f2 = CP.NonlinearScalarFactor(MOI.SingleVariable(y))
            fp = CP.NonlinearScalarProductFunction([f1, f2])
            f = F(fp)

            f_copy = copy(f)
            f_copy.factors[1].expr.factors[2] = CP.NonlinearScalarFactor(MOI.SingleVariable(x))
            @test f != f_copy
            @test f.factors[1].expr.factors[2].expr == MOI.SingleVariable(y)
        end

        @testset "ProductFunction" begin
            x = MOI.VariableIndex(1)
            y = MOI.VariableIndex(2)

            f = CP.ProductFunction(MOI.SingleVariable(x), MOI.SingleVariable(y))

            f_copy = copy(f)
            f_copy.factors[2] = CP.NonlinearScalarFactor(MOI.SingleVariable(x))
            @test f != f_copy
            @test f.factors[2].expr == MOI.SingleVariable(y)
        end

        @testset "$F" for F in [
                CP.AbsoluteValueFunction, CP.ExponentialFunction, CP.LogarithmFunction, 
                CP.CosineFunction, CP.SineFunction, CP.TangentFunction, 
                CP.ArcCosineFunction, CP.ArcSineFunction, CP.ArcTangentFunction, 
                CP.HyperbolicCosineFunction, CP.HyperbolicSineFunction, CP.HyperbolicTangentFunction, 
                CP.HyperbolicArcCosineFunction, CP.HyperbolicArcSineFunction, CP.HyperbolicArcTangentFunction,
            ]
            x = MOI.VariableIndex(1)
            y = MOI.VariableIndex(2)

            f1 = CP.NonlinearScalarFactor(MOI.SingleVariable(x))
            f2 = CP.NonlinearScalarFactor(MOI.SingleVariable(y))
            fp = CP.NonlinearScalarProductFunction([f1, f2])
            f = F(fp)

            f_copy = copy(f)
            f_copy.expr.factors[2] = CP.NonlinearScalarFactor(MOI.SingleVariable(x))
            @test f != f_copy
            @test f.expr.factors[2].expr == MOI.SingleVariable(y)
        end
    end
end
