# Potential contributions to MOI.

# # --- operate_coefficient with three arguments: coefficient, 
# # first variable or nothing, second variable or nothing.

# function operate_index_coefficient(f, term::MOI.ScalarAffineTerm)
#     return MOI.ScalarAffineTerm(f(term.coefficient, term.variable, nothing), term.variable)
# end
# function operate_index_coefficient(f, term::MOI.ScalarQuadraticTerm)
#     return MOI.ScalarQuadraticTerm(
#         f(term.coefficient, term.variable_1, term.variable_2),
#         term.variable_1,
#         term.variable_2,
#     )
# end
# function operate_index_coefficient(f, term::MOI.VectorAffineTerm)
#     return MOI.VectorAffineTerm(
#         term.output_index,
#         operate_index_coefficient(f, term.scalar_term),
#     )
# end
# function operate_index_coefficient(f, term::MOI.VectorQuadraticTerm)
#     return MOI.VectorQuadraticTerm(
#         term.output_index,
#         operate_index_coefficient(f, term.scalar_term),
#     )
# end

# function operate_index_coefficients(f, func::MOI.ScalarAffineFunction)
#     return MOI.ScalarAffineFunction(
#         [operate_coefficient(f, term) for term in func.terms],
#         f(func.constant, nothing, nothing),
#     )
# end
# function operate_index_coefficients(f, func::MOI.ScalarQuadraticFunction)
#     return MOI.ScalarQuadraticFunction(
#         [operate_index_coefficient(f, term) for term in func.affine_terms],
#         [operate_index_coefficient(f, term) for term in func.quadratic_terms],
#         f(func.constant, nothing, nothing),
#     )
# end
# function operate_index_coefficients(f, func::MOI.VectorAffineFunction)
#     return MOI.VectorAffineFunction(
#         [operate_index_coefficient(f, term) for term in func.terms],
#         map(f, func.constants),
#     )
# end
# function operate_index_coefficients(f, func::MOI.VectorQuadraticFunction)
#     return MOI.VectorQuadraticFunction(
#         [operate_index_coefficient(f, term) for term in func.affine_terms],
#         [operate_index_coefficient(f, term) for term in func.quadratic_terms],
#         map(f, func.constants),
#     )
# end

# # --- operate_coefficient with two arguments: coefficient, 
# # number of the output dimension. Only for vector functions.

# function operate_dimension_coefficient(f, term::MOI.VectorAffineTerm)
#     return MOI.VectorAffineTerm(
#         term.output_index,
#         operate_dimension_coefficient(
#             (v) -> f(v, term.output_index), 
#             term.scalar_term,
#         ),
#     )
# end
# function operate_dimension_coefficient(f, term::MOI.VectorQuadraticTerm)
#     return MOI.VectorQuadraticTerm(
#         term.output_index,
#         operate_dimension_coefficient(
#             (v) -> f(v, term.output_index), 
#             term.scalar_term,
#         ),
#     )
# end

# function operate_dimension_coefficients(f, func::MOI.VectorAffineFunction)
#     return MOI.VectorAffineFunction(
#         [operate_dimension_coefficient(f, term) for term in func.terms],
#         map(f, func.constants),
#     )
# end
# function operate_dimension_coefficients(f, func::MOI.VectorQuadraticFunction)
#     return MOI.VectorQuadraticFunction(
#         [operate_dimension_coefficient(f, term) for term in func.affine_terms],
#         [operate_dimension_coefficient(f, term) for term in func.quadratic_terms],
#         map(f, func.constants),
#     )
# end

# # --- from a vector function to a scalar function by summing all components.

# function Base.sum(func::MOI.VectorAffineFunction)
#     return MOIU.canonicalize(
#         MOI.ScalarAffineFunction(
#             [term.scalar_term for term in func.terms], 
#             sum(func.constants)
#         )
#     )
# end
# function Base.sum(func::MOI.VectorQuadraticFunction)
#     return MOIU.canonicalize(
#         MOI.ScalarAffineFunction(
#             [term.scalar_term for term in func.affine_terms], 
#             [term.scalar_term for term in func.quadratic_terms], 
#             sum(func.constants)
#         )
#     )
# end

# --- casting from Bool to Int

# function MOI.ScalarAffineTerm{Int}(t::MOI.ScalarAffineTerm{Bool})
#     return MOI.ScalarAffineTerm{Int}(
#         Int(t.coefficient),
#         t.variable_index,
#     )
# end

# function MOI.VectorAffineTerm{Int}(t::MOI.VectorAffineTerm{Bool})
#     return MOI.VectorAffineTerm{Int}(
#         t.output_index,
#         MOI.ScalarAffineTerm{Int}(t.scalar_term),
#     )
# end

# function MOI.ScalarAffineFunction{Int}(f::MOI.ScalarAffineFunction{Bool})
#     return MOI.ScalarAffineFunction{Int}(
#         MOI.ScalarAffineTerm{Int}.(f.terms),
#         Int(f.constant),
#     )
# end

# function MOI.VectorAffineFunction{Int}(f::MOI.VectorAffineFunction{Bool})
#     return MOI.VectorAffineFunction{Int}(
#         MOI.VectorAffineTerm{Int}.(f.terms),
#         Int.(f.constants),
#     )
# end
