# =============================================================================
# =
# = Import from the FlatZinc format.
# =
# =============================================================================

function Base.read!(::IO, ::Optimizer)
    error("read! is not implemented for FlatZinc (fzn) files.")
    return nothing
end
