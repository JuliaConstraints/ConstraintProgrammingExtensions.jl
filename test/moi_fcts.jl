@testset "Nonlinear functions" begin
    x = MOI.VariableIndex(1)
    y = MOI.VariableIndex(2)

    @testset "Copy" begin
        @testset "NonlinearScalarAffineFunction" begin
            t1 = CP.NonlinearScalarAffineTerm(MOI.SingleVariable(x))
            t2 = CP.NonlinearScalarAffineTerm(MOI.SingleVariable(y))
            f = CP.NonlinearScalarAffineFunction([t1, t2])

            f_copy = copy(f)
            f_copy.terms[2] = CP.NonlinearScalarAffineTerm(MOI.SingleVariable(x))
            @test f != f_copy
            @test f.terms[2].expr == MOI.SingleVariable(y)
        end

        @testset "NonlinearScalarProductFunction" begin
            f1 = CP.NonlinearScalarFactor(MOI.SingleVariable(x))
            f2 = CP.NonlinearScalarFactor(MOI.SingleVariable(y))
            f = CP.NonlinearScalarProductFunction([f1, f2])

            f_copy = copy(f)
            f_copy.factors[2] = CP.NonlinearScalarFactor(MOI.SingleVariable(x))
            @test f != f_copy
            @test f.factors[2].expr == MOI.SingleVariable(y)
        end

        @testset "$F" for F in [CP.SquareRootFunction, CP.InverseFunction]
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

    @testset "Compatibility with MOI linear and quadratic" begin
        @testset "MOI.ScalarAffineTerm" begin
            t = MOI.ScalarAffineTerm(1.0, x)
            f = CP.NonlinearScalarAffineTerm(t)

            @test f.coefficient === 1.0
            @test f.expr === MOI.SingleVariable(x)
        end
        
        @testset "MOI.ScalarAffineFunction" begin
            t1 = MOI.ScalarAffineTerm(1.0, x)
            t2 = MOI.ScalarAffineTerm(2.0, y)
            fa = MOI.ScalarAffineFunction([t1, t2], 0.0)
            f = CP.NonlinearScalarAffineFunction(fa)

            @test f.terms[1].coefficient === 1.0
            @test f.terms[1].expr === MOI.SingleVariable(x)
            @test f.terms[2].coefficient === 2.0
            @test f.terms[2].expr === MOI.SingleVariable(y)
        end
        
        @testset "MOI.ScalarQuadraticTerm" begin
            t = MOI.ScalarQuadraticTerm(1.0, x, y)
            f = CP.NonlinearScalarAffineTerm(t)

            @test f.coefficient === 1.0
            @test f.expr.factors[1].exponent === 1.0
            @test f.expr.factors[1].expr === MOI.SingleVariable(x)
            @test f.expr.factors[2].exponent === 1.0
            @test f.expr.factors[2].expr === MOI.SingleVariable(y)
        end
        
        @testset "MOI.ScalarQuadraticFunction" begin
            t1 = MOI.ScalarAffineTerm(1.0, x)
            t2 = MOI.ScalarAffineTerm(2.0, y)
            tq = MOI.ScalarQuadraticTerm(1.0, x, y)
            fq = MOI.ScalarQuadraticFunction([t1, t2], [tq], 0.0)
            f = CP.NonlinearScalarAffineFunction(fq)

            @test f.terms[1].coefficient === 1.0
            @test f.terms[1].expr === MOI.SingleVariable(x)
            @test f.terms[2].coefficient === 2.0
            @test f.terms[2].expr === MOI.SingleVariable(y)
        end
    end
end
