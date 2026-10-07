"""Canonical JuliaConstraints semantic identity for supported MOI/CP set types."""
semantic_id(::Type{<:MOI.AllDifferent}) = :all_different
semantic_id(::MOI.AllDifferent) = :all_different
"""Variant within a canonical JuliaConstraints semantic family."""
semantic_variant(::Type{<:MOI.AllDifferent}) = :standard
semantic_variant(::MOI.AllDifferent) = :standard

semantic_id(::Type{<:AllDifferentExceptConstants}) = :all_different
semantic_id(::AllDifferentExceptConstants) = :all_different
semantic_variant(::Type{<:AllDifferentExceptConstants}) = :except_constants
semantic_variant(::AllDifferentExceptConstants) = :except_constants

semantic_id(::Type{<:XCSP3AllDifferent}) = :all_different
semantic_id(::XCSP3AllDifferent) = :all_different
semantic_variant(::Type{<:XCSP3AllDifferent}) = :xcsp3
semantic_variant(::XCSP3AllDifferent) = :xcsp3

semantic_id(::Type{<:XCSP3Sum}) = :sum
semantic_id(::XCSP3Sum) = :sum
semantic_variant(::Type{<:XCSP3Sum}) = :xcsp3
semantic_variant(::XCSP3Sum) = :xcsp3

for (set_type, identity) in ((XCSP3Count, :count), (XCSP3NValues, :nvalues),
        (XCSP3Cardinality, :cardinality))
    @eval begin
        semantic_id(::Type{<:$set_type}) = $(QuoteNode(identity))
        semantic_id(::$set_type) = $(QuoteNode(identity))
        semantic_variant(::Type{<:$set_type}) = :xcsp3
        semantic_variant(::$set_type) = :xcsp3
    end
end

semantic_id(::Type{<:CumulativeResource}) = :cumulative
semantic_id(::CumulativeResource) = :cumulative
semantic_variant(::Type{CumulativeResource{NO_DEADLINE_CUMULATIVE_RESOURCE}}) = :fixed_lengths
semantic_variant(::Type{CumulativeResource{VARIABLE_DEADLINE_CUMULATIVE_RESOURCE}}) =
    :variable_deadlines
semantic_variant(set::CumulativeResource) = semantic_variant(typeof(set))

"""Version of the stable semantic-identity contract."""
semantic_version(::Type) = v"1.0.0"
semantic_version(value) = semantic_version(typeof(value))

semantic_id(::Type{<:XCSP3Core{K}}) where {K} = K
semantic_id(::XCSP3Core{K}) where {K} = K
semantic_variant(::Type{<:XCSP3Core}) = :xcsp3
semantic_variant(::XCSP3Core) = :xcsp3
