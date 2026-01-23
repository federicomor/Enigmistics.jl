"""
    is_pangram(s::AbstractString; language="en", verbose=false)

Check if a string is a pangram, i.e. if it contains at least once all the letters of the alphabet.

The `language` parameter can be used to specify which alphabet to use (currently supported values are "en", English and "it", Italian). In particular, the english case consists of the vector `collect('a':'z')` while the italian one of the english vector having removed characters `'jwxyz'`. If `verbose` is set to `true` the function will also inform, in case of non-pangrams, which were the missing letters.

See also [`scan_for_pangrams`](@ref).

# Examples
```julia-repl
julia> is_pangram("The quick ORANGE fox jumps over the lazy dog", verbose=true)
[ Info: Missing character(s): ['b', 'w']
false

julia> is_pangram("The quick BROWN fox jumps over the lazy dog", verbose=true)
true

julia> is_pangram("Pranzo d'acqua fa volti sghembi") # false due to the default alphabet being english
false

julia> is_pangram("Pranzo d'acqua fa volti sghembi", language="it")
true
```
"""
function is_pangram(s::AbstractString; language="en", verbose=false, normalize=true)
    if normalize s = normalize_accents(lowercase(s)) end
    # @info s
    alphabet = language_corrections[language]
    s_set = Set(collect(s))
    out = setdiff(alphabet,s_set)
    if isempty(out)
        return true
    else
        if verbose @info "Missing character(s): $out" end
        return false
    end
end

function highlight_letter(s::AbstractString, letters::String)
    for c in s
        # @show c
        if occursin(strip_text(c),strip_text(letters))
            printstyled(c, underline=false, bold=true, color=:magenta)
            # print("_$c _")
        else
            print(c)
        end
    end
end
highlight_letter(s::AbstractString, letter::Char) = highlight_letter(s::AbstractString, string(letter))


# highlight_letter("The quick brown fox jumps over the lazy dog","bw")
# highlight_letter("Davvero è così","è")

# is_pangram("The quick orange fox jumps over the lazy dog", verbose=true)
# is_pangram("The quick brown fox jumps over the lazy dog", verbose=true)
# is_pangram("Pranzo d'acqua fa volti sghembi") # false due to the default alphabet being english
# is_pangram("Pranzo d'acqua fa volti sghembi", language="it")
# is_pangram("Pranzò d'acqùa fa vòlti sghembi", language="it")
# is_pangram("Pranzò d'acqùa fa vòlti sghembi", language="it", normalize=false)



"""
```
scan_for_pangrams(text::String; 
    max_length_letters=60, language="en", verbose=false, print_results=false)
```

Scan a text and look for sequences of words which are pangrams.

Return a vector of matches in the form `(matching_range, matching_string)`.

# Arguments
- `text`: the input text to scan
- `max_length_letters=60`: consider only sequences of words with at most this number of letters
- `language="en"`: language used to determine the alphabet
- `print_results=false`: whether to print results or just return them

See also [`is_pangram`](@ref).

# Examples
```julia-repl
julia> text = clean_read("../texts/paradise_lost.txt", newline_replace="/");

julia> scan_for_pangrams(text, max_length_letters=80, language="en")
1-element Vector{Any}:
 (21698:21804, "Grazed Ox, / JEHOVAH, who in one Night when he pass'd / From EGYPT marching, equal'd with one stroke / Both")

julia> text = clean_read("../texts/divina_commedia.txt", newline_replace="/"); 

julia> scan_for_pangrams(text, max_length_letters=50, language="it")
5-element Vector{Any}:
 (247196:247259, "aveste'. / E 'l buon maestro: \"Questo cinghio sferza la colpa de")
 (247196:247262, "aveste'. / E 'l buon maestro: \"Questo cinghio sferza la colpa de la")
 (247207:247270, "E 'l buon maestro: \"Questo cinghio sferza la colpa de la invidia")
 (247210:247273, "l buon maestro: \"Questo cinghio sferza la colpa de la invidia, e")
 (482359:482421, "probo. / Vidi la figlia di Latona incensa sanza quell'ombra che")
```
"""
function scan_for_pangrams(text::AbstractString; max_length_letters::Int=80,
                            language::String="en", verbose::Bool=false,
                            print_results::Bool=false)

    # precompute words and positions
    cleaned_text = normalize_accents(lowercase(text))
    # matches = collect(eachmatch(r"\w+", text))
    matches = collect(eachmatch(r"\p{L}+", text))
    words = [m.match for m in matches]
    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]
    n = length(words)

    results = []
    clean_candidate = ""
    candidate = ""
    pool_words = [] # each element: (word, start_char, end_char)
    p = Progress(n, desc="Scanning for pangrams...")

    for i in 1:n
        # add next word to pool
        push!(pool_words, (words[i], starts[i], ends[i]))

        # shrink pool from front if too long
        while sum(count_letters(w[1]) for w in pool_words) > max_length_letters && length(pool_words) >= 2
            popfirst!(pool_words)
        end

        if !isempty(pool_words)
            start_char = pool_words[1][2]
            end_char = pool_words[end][3]
            clean_candidate = SubString(cleaned_text, start_char:end_char)
            if is_pangram(clean_candidate, language=language, verbose=verbose, normalize=false)
                candidate = SubString(text, start_char:end_char)
                push!(results, (start_char:end_char, candidate))
            end
        end

        next!(p)
    end

    if print_results
        println("Pangrams found:")
        for (idx, (rng, phrase)) in enumerate(results)
            # println(lpad(idx,2), ") ", rng, ": ", phrase)
            println(lpad(idx, 2), ") ($(count_letters(phrase)) letters) ", rng, ": ", phrase)
        end
    end

    return results
end


text = clean_read("texts/paradise_lost.txt", newline_replace="/"); text[1:100]
# text = snip(text,21698:21804,20)
@time scan_for_pangrams(text, max_length_letters=80, language="en",print_results=true)
# text = clean_read("../texts/divina_commedia.txt", newline_replace="/"); text[1:100]
# @time scan_for_pangrams(text, max_length_letters=50, language="it")
