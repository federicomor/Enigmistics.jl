"""
    is_lipogram(s::AbstractString, wrt::AbstractString)

Check if a string `s` is a lipogram with respect to the letters given by `wrt`, i.e. if `s` does not contain any letters from `wrt`. 
    
The parameter `wrt` is a string so that single or multiple letters can be easily specified.

See also [`scan_for_lipograms`](@ref).

# Examples
```jldoctest
julia> is_lipogram("If youth, throughout all history, had had a champion to stand up for it; to show 
       a doubting world that a child can think; and, possibly, do it practically; you wouldn’t constantly
       run across folks today who claim that “a child don’t know anything.” A child’s brain starts
       functioning at birth; and has, amongst its many infant convolutions, thousands of dormant
       atoms, into which God has put a mystic possibility for noticing an adult’s act, and figuring
       out its purport", "e", verbose=true)
true

julia> is_lipogram("The quick brown fox","abc",verbose=true)
[ Info: Letter(s) present from wrt: Set(['c', 'b'])
false
```
"""
function is_lipogram(s::AbstractString, wrt::AbstractString; verbose=false)
    s = strip_text(s)
    wrt_set = Set(normalize_accents(lowercase(c)) for c in wrt if isletter(c))
    for c in s
        isletter(c) || continue # skip non-letters (eg. spaces, punctuation)
        if c in wrt_set
            if verbose
                @info "Letter(s) present from wrt: $(intersect(wrt_set, Set(c for c in s if isletter(c))))"
                highlight_letter(s,wrt); println()
            end
            return false
        end
    end
    return true
end

# @time is_lipogram("This is a small thought without using a famous symbol following D","e", verbose=true)
# @time is_lipogram("The quick brown fox jumps over the lazy cat","dgef",verbose=true) # 'd' and 'g' are missing
# @time is_lipogram("The quick brown fox","abc",verbose=true) # 'd' and 'g' are missing

"""
```
scan_for_lipograms(text::String, wrt::String; 
    min_length_letters=30, max_length_letters=100, print_results=false)
```

Scan a text and look for sequences of words that are lipograms with respect to the letters given by `wrt`.

Return a vector of matches in the form `(matching_range, matching_string)`.

# Arguments
- `text`: the input text to scan
- `min_length_letters=30`: consider only sequences of words with at least this number of letters
- `max_length_letters=100`: consider only sequences of words with at most this number of letters
- `print_results=false`: whether to print results or just return them

See also [`is_lipogram`](@ref).

# Examples
```jldoctest
julia> text = clean_read("../texts/all_shakespeare.txt", newline_replace="/");

julia> scan_for_lipograms(text, "eta", min_length_letters=34) # E, T and A are the most common letters in english
3-element Vector{Any}:
 (1480855:1480902, "up your sword. / NYM. Will you shog off? I would")
 (3647302:3647352, "in music. [Sings.] \"Willow, willow, willow.\" / Moor")
 (3966201:3966245, "LORDS. Good morrow, Richmond! / RICHMOND. Cry")
```
"""
function scan_for_lipograms(text::String, wrt::String;
                            min_length_letters::Int=30,max_length_letters::Int=100,
                            print_results::Bool=false)

    # precompute words and positions
    matches = collect(eachmatch(r"\p{L}+", text)) # separe words by runs of letters only
    words = [m.match for m in matches]
    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]

    n = length(words)
    results = []
    p = Progress(n, desc="Scanning for lipograms...")

    for i in 1:n
        for j in i:n
            # Extract substring from original text
            phrase = text[starts[i]:ends[j]]
            len = count_letters(phrase)

            if len > max_length_letters
                break
            end
            if len >= min_length_letters
                if is_lipogram(phrase, wrt)
                    push!(results, (starts[i]:ends[j], phrase))
                else
                    break # no point in extending further; 
                    # adding words wont make a lipogram if the curernt one already is not
                end
            end
        end
        next!(p)
    end

    if print_results
        println("Lipograms found:")
        if length(results) == 0
            println("(none)"); return results
        end
        for (idx, (rng, phrase)) in enumerate(results)
            println(lpad(idx, 2), ") ($(count_letters(phrase)) letters) ", rng, ": ", phrase)
        end
    end

    return results
end

# text = clean_read("texts/paradise_lost.txt", newline_replace="/"); text[1:100]
# @time scan_for_lipograms(text, "ea", min_length_letters=40,print_results=true)
