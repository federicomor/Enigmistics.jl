"""
    is_tautogram(s::AbstractString)    

Check if a given string is a tautogram, i.e., all words in the string start with the same letter.

See also [`scan_for_tautograms`](@ref).

# Examples
```julia-repl
julia> is_tautogram("Disney declared: 'Donald Duck definitely deserves devotion'")
true

julia> is_tautogram("She sells sea shells by the sea shore.") # "by" and "the" break the s-streak
false
```
"""
function is_tautogram(s::AbstractString)
    matches = collect(eachmatch(r"\w+", s))
    words = [m.match for m in matches]
    words = lowercase.(words)
    first_letter = words[1][1]
    for w in words
        # @show w[1]
        if w[1] != first_letter
            return false
        end
    end
    return isletter(first_letter)
end

# is_tautogram("Disney declared: 'Donald Duck definitely deserves devotion'")
# is_tautogram("She sells sea shells by the sea shore.") # "by" and "the" break the s-streak 


"""
    scan_for_tautograms(text::String; min_length_words=5, max_length_words=20, print_results=false)

Scan a text and look for sequences of words which are tautograms.

Return a vector of matches in the form `(matching_range, matching_string)`.

# Arguments
- `text`: the input text to scan
- `min_length_words=5`: consider only sequences with at least this number of words
- `max_length_words=20`: consider only sequences with at most this number of words
- `print_results=false`: whether to print results or just return them

See also [`is_tautogram`](@ref).

# Examples
```julia-repl
julia> text = clean_read("../texts/paradise_lost.txt", newline_replace="/");

julia> scan_for_tautograms(text, min_length_words=5, max_length_words=20)
6-element Vector{Any}:
 (20801:20830, "and ASCALON, / And ACCARON and")
 (110257:110281, "Topaz, to the Twelve that")
 (136170:136194, "to taste that Tree, / The")
 (320005:320030, "her Husbands hand her hand")
 (450274:450301, "Though to the Tyrant thereby")
 (456113:456141, "Through the twelve Tribes, to")
```
"""
function scan_for_tautograms(text::String;
                            min_length_words::Int=5, 
                            max_length_words::Int=30,
                            print_results::Bool=false)

    # Precompute words and positions
    matches = collect(eachmatch(r"\w+", text))
    words = [m.match for m in matches]
    # words = lowercase.(filter.(x->isletter(x),words))
    # words = lowercase.(words)
    # @show words
    initials = [lowercase(w[1]) for w in words]
    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]

    n = length(words)
    @assert n == length(initials)
    results = []
    resulting_words = []

    p = Progress(n, desc="Scanning for tautograms...")
    for i in 1:n
        for j in i:n
            # Extract substring from original text
            pool = initials[i:j]
            len = length(pool)

            if len > max_length_words
                break
            end
            if len >= min_length_words
                if allequal(pool)
                    rng = starts[i]:ends[j]
                    push!(results, (rng, text[rng]))
                    push!(resulting_words, words[i:j])
                else 
                    break # no point in extending further; 
                    # adding words wont make a tautogram if the curernt one already is not
                end
            end
        end
        next!(p)
    end

    if print_results
        println("Tautograms found:")
        for (idx, (rng, phrase)) in enumerate(results)
            # println(lpad(idx, 2), ") ", rng, ": ", phrase)
            println(lpad(idx, 2), ") ($(length(resulting_words[idx])) words, $(count_letters(phrase)) chars) ", rng, ": ", text[rng])
        end
    end

    return results
end

# text = clean_read("../texts/paradise_lost.txt", newline_replace="/"); text[1:100]
# out = scan_for_tautograms(text, min_length_words=5, max_length_words=20, print_results=true)
# text = clean_read("../texts/divina_commedia.txt", newline_replace="/"); text[1:100]
# out = scan_for_tautograms(text, min_length_words=4, max_length_words=20, print_results=true)

