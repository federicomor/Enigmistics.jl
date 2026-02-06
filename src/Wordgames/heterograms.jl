"""
    is_heterogram(s::AbstractString)

Check if a string is a heterogram, i.e. if it does not contain any repeated letter.

See also [`scan_for_heterograms`](@ref).

# Examples
```jldoctest
julia> is_heterogram("unpredictable") # letter 'e' is repeated
false

julia> is_heterogram("unpredictably")
true

julia> is_heterogram("The big dwarf only jumps")
true
```
"""
function is_heterogram(s::AbstractString)
    s = strip_text(s)
    seen = Set{Char}()
    for c in s
        isletter(c) || continue # skip non-letters (eg. spaces, punctuation)
        c in seen && return false
        push!(seen, c)
    end
    return true
end

# @assert is_heterogram("èeé") == false
# @time is_heterogram("unpredictable") # letter 'e' is repeated
# @time is_heterogram("unpredictably")
# @time is_heterogram("The big dwarf only jumps")

"""
```
scan_for_heterograms(text::String; 
    min_length_letters=10, print_results=false)
```

Scan a text and look for sequences of words which are heterograms.

Return a vector of matches in the form `(matching_range, matching_string)`.

# Arguments
- `text`: the input text to scan
- `min_length_letters=10`: consider only sequences of words with at most this number of letters
- `print_results=false`: whether to print results or just return them

See also [`is_heterogram`](@ref).

# Examples
```julia-repl
julia> text = clean_read("../texts/ulyss.txt", newline_replace="/");

julia> scan_for_heterograms(text, min_length_letters=15)
15-element Vector{Any}:
 (49809:49825, "and wheysour milk")
 (118616:118634, "a stocking: rumpled")
 (118618:118634, "stocking: rumpled")
 (332294:332312, "and forks? Might be")
 (424648:424664, "himself onward by")
 (478503:478519, "them quickly down")
 (498743:498759, "brought pad knife")
 (506800:506815, "rocky thumbnails")
 (518991:519009, "forms, a bulky with")
 (691836:691852, "with golden syrup")
 (707229:707245, "quickly and threw")
 (992565:992581, "THEM DOWN QUICKLY")
 (1349721:1349737, "and chrome tulips")
 (1442707:1442724, "myself go with and")
 (1442899:1442916, "with my legs round")
```
"""
function scan_for_heterograms(text::String;
                            min_length_letters::Int=15,
                            print_results::Bool=false)

    # precompute words and positions
    matches = collect(eachmatch(r"\p{L}+", text)) # separe words by runs of letters only
    words = [m.match for m in matches]
    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]

    n = length(words)
    results = []
    p = Progress(n, desc="Scanning for heterograms...")

    for i in 1:n
        for j in i:n
            # extract substring from original text
            phrase = text[starts[i]:ends[j]]
            len = count_letters(phrase)

            if len >= min_length_letters
                if is_heterogram(phrase)
                    push!(results, (starts[i]:ends[j], phrase))
                else 
                    break # no point in extending further; 
                    # adding words wont make a heterogram if the curernt one already is not
                end
            end
        end
        next!(p)
    end

    if print_results
        println("Heterograms found:")
        if length(results) == 0
            println("(none)"); return results
        end
        for (idx, (rng, phrase)) in enumerate(results)
            println(lpad(idx, 2), ") ($(count_letters(phrase)) letters) ", rng, ": ", phrase)
        end
    end

    return results
end

# text = clean_read("texts/ulyss.txt", newline_replace="/");
# @time scan_for_heterograms(text, min_length_letters=15, print_results=true)
