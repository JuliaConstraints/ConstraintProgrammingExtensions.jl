# =============================================================================
# =
# = Import from the FlatZinc format.
# =
# =============================================================================

@enum FznParserstate FznPredicate FznParameter FznVar FznConstraint FznSolve FznDone

const FZN_PARAMETER_TYPES_PREFIX = String["bool", "int", "float", "set of int", "array"]

function Base.read!(io::IO, model::Optimizer)
    if !MOI.is_empty(model)
        error("Cannot read in file because model is not empty.")
    end

    # Start parsing loop.
    state = FznPredicate
    while !eof(io)
        # Consistency check: in FznDone state, nothing else can be read.
        if state == FznDone
            break
        end

        # Read an item from the file.
        item = get_fzn_item(io)
        
        # When get_fzn_item returns an empty line, it has not found any more 
        # item to parse.
        if isempty(item)
            break
        end

        # Depending on the state, different tokens are expected. Not all 
        # statees must be reached for all files: only FznSolve is mandatory, 
        # according to the grammar.
        if state == FznPredicate
            if startswith(item, "predicate")
                parse_predicate!(item, model)
            else
                state = FznParameter
            end
        end

        if state == FznParameter
            if any(startswith(item, par_type) for par_type in FZN_PARAMETER_TYPES_PREFIX)
                parse_parameter!(item, model)
            else
                state = FznVar
            end
        end

        if state == FznVar
            if startswith(item, "var")
                parse_variable!(item, model)
            else
                state = FznConstraint
            end
        end

        if state == FznConstraint
            if startswith(item, "constraint")
                parse_constraint!(item, model)
            else
                state = FznSolve
            end
        end

        if state == FznSolve
            if startswith(item, "solve")
                parse_constraint!(item, model)
                state = FznDone
            else
                error("Syntax error: expected a solve-item.")
            end
        end
    end

    return nothing
end

# -----------------------------------------------------------------------------
# - High-level parsing functions.
# -----------------------------------------------------------------------------

function parse_predicate!(item::String, model::Optimizer)
    error("Predicates are not supported.")
    return nothing
end

function parse_parameter!(item::String, model::Optimizer)
    error("Parameters are not supported.")
    return nothing
end

function parse_variable!(item::String, model::Optimizer)
    var_type, var_name, var_annotations, var_value = split_variable(item)
    return nothing
end

function parse_constraint!(item::String, model::Optimizer)
    error("Constraints are not supported.")
    return nothing
end

function parse_solve!(item::String, model::Optimizer)
    error("Solves are not supported.")
    return nothing
end

# -----------------------------------------------------------------------------
# - String-level parsing functions.
# -----------------------------------------------------------------------------

function get_fzn_item(io::IO)
    # A FlatZinc item is delimited by a semicolon (;) at the end. Return one 
    # complete such item, excluding any comments.
    item = ""
    while !eof(io)
        c = read(io, Char)

        # A comment starts with a percent (%) and ends at the end of the line.
        # Stop reading this character and continue normally at the next line.
        if c == '%'
            readline(io)

            # If something was read, return this item. If not, continue reading.
            if length(string(strip(item))) == 0
                continue
            else
                break
            end
        end

        # Push the new character into the string.
        item *= c

        # An item is delimited by a semicolon.
        if c == ';'
            break
        end
    end
    return string(strip(item))
end

function split_variable(item::String)
    @assert length(item) > 4

    if startswith(item, "var")
        return split_variable_scalar(item)
    elseif startswith(item, "array") && occursin("var", item)
        return split_variable_array(item)
    else
        @assert false
    end
end

function split_variable_scalar(item::String)
    # Get rid of the "var" keyword at the beginning. 
    @assert item[1:3] == "var"
    item = lstrip(item[4:end])

    # Split on the colon (:): the type of the variable is before.
    var_type, item = split(item, ':', limit=2)
    var_type = strip(var_type)
    item = lstrip(item)

    # Potentially split on the double colon (::) to detect annotations, then
    # on the equal (=) to detect literal values.
    if occursin("::", item)
        var_name, item = split(item, "::", limit=2)
        var_name = strip(var_name)
        item = lstrip(item)

        if occursin('=', item)
            var_annotations, item = split(item, '=', limit=2)
            var_annotations = strip(var_annotations)
            item = lstrip(item)

            var_value, item = split(item, ';', limit=2)
            var_value = strip(var_value)
        else
            var_annotations, item = split(item, ';', limit=2)
            var_annotations = strip(var_annotations)
            var_value = ""
        end
    else
        var_annotations = ""

        if occursin('=', item)
            var_name, item = split(item, '=', limit=2)
            var_name = strip(var_name)
            item = lstrip(item)

            var_value, item = split(item, ';', limit=2)
            var_value = strip(var_value)
        else
            var_name, item = split(item, ';', limit=2)
            var_name = strip(var_name)
            var_value = ""
        end
    end
    
    return ("", var_type, var_name, var_annotations, var_value)
end

function split_variable_array(item::String)
    # Get rid of the "array" keyword at the beginning. 
    @assert item[1:5] == "array"
    item = lstrip(item[6:end])

    # Split on the "of" keyword: the array definition is before, the rest is a 
    # normal variable definition.
    var_array, item = split(item, "of", limit=2)
    var_array = strip(var_array)
    item = string(lstrip(item))

    # Parse the rest of the line.
    _, var_type, var_name, var_annotations, var_value = split_variable_scalar(item)
    
    return (var_array, var_type, var_name, var_annotations, var_value)
end
