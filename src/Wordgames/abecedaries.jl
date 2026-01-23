"""
    is_abecedary(s::AbstractString; language="en")

Check if a string is an abecedary, i.e. if it consists of a sequence of words whose initials are in alphabetical order.

The `language` parameter can be used to specify which alphabet to use (currently supported values are "en", English and "it", Italian). In particular, the english case consists of the vector `collect('a':'z')` while the italian one of the english vector having removed characters `'jwxyz'`. 

See also [`scan_for_abecedaries`](@ref).

# Examples
```jldoctests
julia> is_abecedary( # from Isidoro Bressan, "La Stampa", 18/10/1986
       "Amore baciami! Con dolci effusioni fammi gioire! Ho illibate labbra, 
       meraviglioso nido ove puoi quietare recondita sensualità traboccante. 
       Ubriachiamoci vicendevolmente, Zaira!", language="it")
true

julia> is_abecedary("A Bright Celestial Dawn Emerges")
true

julia> is_abecedary("A Bright Celestial Dawn Rises") # R breakes the alphabetic streak
false

julia> is_abecedary("Testing: u v w x y z a b c") # wraps by default around the alphabet
true
```
"""
function is_abecedary(s::AbstractString; language="en")
    # words = split(s, c -> !isletter(c), keepempty=false)
    # words = @. normalize_accents(lowercase(words))
    words = split(strip_text(s))
    length(words) < 2 && return false

    idx_map = alphabet_index[language] # see constants.jl for more details

    first_letter = lowercase(words[1][1])
    # find starting index (without allocating)
    idx = get(idx_map, first_letter, 0)
    # so avoiding this:
    # idx = findfirst(alphabet .== words[1][1]) 
    # or this:
    # idx = 0; for i in 1:la
    #     if alphabet[i] == first_letter
    #         idx = i; break
    #     end
    # end
    idx == 0 && return false

    la = length(idx_map)
    for k in 2:length(words)
        idx = mod1(idx + 1, la)
        if !haskey(idx_map, lowercase(words[k][1])) ||
           idx_map[lowercase(words[k][1])] != idx
            return false
        end
    end

    return true
end


# s = "ma non oppure possiamo? la volpe bianca ch'alzava 'l muso. salta sopra il cane grigio"
# s_set = split(s,r"[ |'|.]+")
# s_set = split(s,c -> !isletter(c), keepempty=false)

# is_abecedary("Amore baciami! Con dolci effusioni fammi 
#     gioire! Ho illibate labbra, meraviglioso nido ove puoi 
#     quietare recondita sensualità traboccante. Ubriachiamoci 
#     vicendevolmente, Zaira!", language="it")
# is_abecedary("Love me! Not only ...", language="it")
# @time is_abecedary("Amore baciami! Con dolci effusioni fammi giore!", language="it")

# is_abecedary("A bright, clear day, xen", language="it")
# is_abecedary("A bright, lovely day") # the L of lovely breaks the alphabetic streak
# @time is_abecedary("Testing: u v w x y z a b c") # wraps by default around the alphabet

"""
```
scan_for_abecedaries(text::String; 
    min_length_words=4, max_length_words=30, 
    language="en", print_results=false) 
```

Scan a text and look for sequences of words which are abecedaries.

Return a vector of matches in the form `(matching_range, matching_string)`.

# Arguments
- `text`: the input text to scan
- `min_length_words=4`: consider only sequences with at least this number of words
- `max_length_words=30`: consider only sequences with at most this number of words
- `language="en"`: language used to determine the alphabet
- `print_results=false`: whether to print results or just return them

See also [`is_abecedary`](@ref).

# Examples
```jldoctest
julia> text = clean_read("texts/paradise_lost.txt", newline_replace="/");

julia> scan_for_abecedaries(text, min_length_words=4, max_length_words=5, language="en")
3-element Vector{Any}:
 (102463:102490, "a boundless Continent / Dark")
 (368827:368846, "raging Sea / Tost up")
 (405485:405502, "and both confess'd")

julia> text = clean_read("texts/divina_commedia.txt", newline_replace="/");

julia> scan_for_abecedaries(text, min_length_words=4, max_length_words=5, language="it")
7-element Vector{Any}:
 (41947:41969, "per questo regno. / Sol")
 (251201:251214, "che dire e far")
 (286372:286400, "crucifisso, dispettoso e fero")
 (456131:456152, "cera dedutta / e fosse")
 (463117:463142, "albor balenar Cristo. / Di")
 (498374:498404, "O predestinazion, quanto remota")
 (508390:508415, "con digiuno, / e Francesco")
```
"""
function scan_for_abecedaries(text::AbstractString; 
                            min_length_words::Int=4, max_length_words=30, language::String="en",
                            print_results::Bool=false)

    # Precompute words and positions
    # matches = collect(eachmatch(r"\w+", text))
    matches = collect(eachmatch(r"\p{L}+", text))
    words = [m.match for m in matches]
    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]

    n = length(words)
    results = []
    p = Progress(n, desc="Scanning for abecedaries...")

    for i in 1:n
        # grow window forward
        for j in i+1:min(i + max_length_words - 1, n)
            len = j - i + 1
            # @info len
            len < min_length_words && continue
            candidate = SubString(text, starts[i]:ends[j])
            # @info "surpassing min_length_words check"
            # @info candidate
            if is_abecedary(candidate, language = language) && length(split(candidate,c -> !isletter(c), keepempty=false)) >= min_length_words
                push!(results, (starts[i]:ends[j], candidate))
            else
                # if this prefix fails, longer ones will also fail
                break
            end
        end
        next!(p)
    end
    if print_results
        println("Abecedaries found:")
        if length(results) == 0
            println("(none)"); return results
        end
        for (idx, (rng, phrase)) in enumerate(results)
            # println(lpad(idx,2), ") ", rng, ": ", phrase)
            println(lpad(idx, 2), ") ($(length(split(phrase,c -> !isletter(c), keepempty=false))) words, $(count_letters(phrase)) chars) ", rng, ": ", phrase)
        end
    end

    return results
end

# s = "Amore baciami! Con dolci effusioni fammi giore!"
# scan_for_abecedaries(s, min_length_words=3, max_length_words=6, language="it", print_results=true)

# text = clean_read("texts/paradise_lost.txt", newline_replace="/");
# scan_for_abecedaries(text, min_length_words=4, max_length_words=5, language="en")
# text = clean_read("texts/divina_commedia.txt", newline_replace="/");
# text = clean_read("texts/tragedie_inni_sacri_odi.txt", newline_replace="/");
# text = snip(text,3875:3896,40)
# scan_for_abecedaries(text, min_length_words=4, max_length_words=4, language="it", print_results=true)

