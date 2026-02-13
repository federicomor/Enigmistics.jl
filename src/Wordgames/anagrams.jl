"""
    are_anagrams(s1::AbstractString, s2::AbstractString; be_strict=true)
    are_anagrams(s1::Vector{String}, s2::Vector{String}; be_strict=true)

Check if two strings are anagrams, i.e. if the letters of one can be rearranged to form the other.

The parameter `be_strict` is defaulted to `true` to avoid considering as anagrams strings where one is simply a permutation of the other.

See also [`scan_for_anagrams`](@ref).

# Examples
```julia-repl
julia> are_anagrams("The Morse Code","Here come dots!") # true anagram
true

julia> are_anagrams("The Morse Code","Morse: the code!") # just a fancy reordering
false

julia> are_anagrams("The Morse Code","Morse: the code!", be_strict=false) # just a fancy reordering, now considered an anagram
true
```
"""
function are_anagrams(s1::AbstractString,s2::AbstractString; be_strict=true)
    s1_clean = strip_text(s1)
    s2_clean = strip_text(s2)

    # collect cleaned letters form each string
    s1_letters = filter(isletter,collect(s1_clean))
    s2_letters = filter(isletter,collect(s2_clean))
    length(s1_letters) != length(s2_letters) && return false

    freq = Dict{Char, Int}()
    for c in s1_letters
        freq[c] = get(freq, c, 0) + 1
    end
    for c in s2_letters
        freq[c] = get(freq, c, 0) - 1
    end
    any(v != 0 for v in values(freq)) && return false
    if be_strict
        # we need to check that the two strings are not just a reordering of the same words
        # so we derive the words, sort them, and compare the result
        return sort(split(s1_clean," ")) != sort(split(s2_clean," "))
    end
    return true
end

function are_anagrams(s1::Vector{AbstractString},s2::Vector{AbstractString}; be_strict=false)
    return are_anagrams(join(s1, " "),join(s2, " "), be_strict=be_strict)
end
function are_anagrams(s1::Vector{SubString{String}},s2::Vector{SubString{String}}; be_strict=false)
    return are_anagrams(join(s1, " "),join(s2, " "), be_strict=be_strict)
end


# helper for the next function
function get_signature(s_clean::AbstractString)
    sig = Dict{Char, Int}()
    for char in s_clean
        sig[char] = get(sig, char, 0) + 1
    end
    return sig
end
"""
```
scan_for_anagrams(text::String; 
    min_length_letters=6, max_length_letters=30, max_distance_words=40, 
    be_strict=true, print_results=false)
```

Scan a text and look for pairs of word sequences which are anagrams.
    
Return a vector of matches in the form `(range1, words1, range2, words2)`.
 
# Arguments
- `text`: the input text to scan
- `min_length_letters=6`: consider only sequences of words with at least this number of letters
- `max_length_letters=30`: consider only sequences of words with at most this number of letters
- `max_distance_words=40`: consider only sequences of words which are at most these words apart
- `be_strict=true`: do not consider as anagrams sequences where one is simply a permutation of the other
- `print_results=false`: whether to print results or just return them

See also [`are_anagrams`](@ref).

# Examples
```julia-repl
julia> text = "Last night I saw a gentleman; he was a really elegant man.";

julia> matches = scan_for_anagrams(text, min_length_letters=1, max_length_letters=14, max_distance_words=10, be_strict=false)
4-element Vector{Any}:
 (14:16, SubString{String}["saw"], 34:36, SubString{String}["was"])
 (14:18, SubString{String}["saw", "a"], 34:38, SubString{String}["was", "a"])
 (18:18, SubString{String}["a"], 38:38, SubString{String}["a"])
 (18:28, SubString{String}["a", "gentleman"], 47:57, SubString{String}["elegant", "man"])

julia> matches = scan_for_anagrams(text, min_length_letters=1, max_length_letters=14, max_distance_words=10, be_strict=true)
3-element Vector{Any}:
 (14:16, SubString{String}["saw"], 34:36, SubString{String}["was"])
 (14:18, SubString{String}["saw", "a"], 34:38, SubString{String}["was", "a"])
 (18:28, SubString{String}["a", "gentleman"], 47:57, SubString{String}["elegant", "man"])

julia> matches = scan_for_anagrams(text, min_length_letters=5, max_length_letters=14, max_distance_words=10)
1-element Vector{Any}:
 (18:28, SubString{String}["a", "gentleman"], 47:57, SubString{String}["elegant", "man"])
```
"""
function scan_for_anagrams(text::String;
                            min_length_letters::Int=6, 
                            max_length_letters::Int=20,
                            max_distance_words::Int=20,
                            print_results=false, be_strict=true)

    # precompute words and positions
    matches = collect(eachmatch(r"\p{L}+", text))
    # words: original text; words_clean: used for strict comparison
    words = [m.match for m in matches]
    words_clean = [normalize_accents(lowercase(m.match)) for m in matches] # Add accent removal here if needed

    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]
    
    # pre-calculate letter counts per word
    word_lens = [length(w) for w in words_clean]

    n = length(matches)
    results = []
    p = Progress(n, desc="Scanning for anagrams...")

    for i in 1:n
        current_len1 = 0
        for j in i:n
            current_len1 += word_lens[j]
            
            if current_len1 > max_length_letters; break; end
            if current_len1 < min_length_letters; continue; end
            
            # Phrase 1 signature (calculated once per valid window)
            phrase1_str = join(words_clean[i:j])
            sig1 = get_signature(phrase1_str)
            
            # Look ahead for pool2
            lookahead_limit = min(n, j + max_distance_words)
            current_len2 = 0
            
            for k in (j+1):lookahead_limit
                current_len2 = 0 # Reset for the start of l-loop
                for l in k:n
                    current_len2 = sum(word_lens[k:l])
                    
                    if current_len2 > max_length_letters; break; end
                    
                    if current_len1 == current_len2
                        phrase2_str = join(words_clean[k:l])
                        sig2 = get_signature(phrase2_str)
                        
                        if sig1 == sig2
                            # STRICT CHECK: Ensure they aren't just the same words rearranged
                            if be_strict
                                if sort(words_clean[i:j]) == sort(words_clean[k:l])
                                    continue # Skip if it's just a word permutation
                                end
                            end
                            
                            push!(results, (starts[i]:ends[j], words[i:j], starts[k]:ends[l], words[k:l]))
                        end
                    end
                end
            end
        end
        next!(p)
    end

    if print_results
        println("Anagrams found:")
        if length(results) == 0
            println("(none)"); return results
        end
        for (idx, (rng1, phrase1, rng2, phrase2)) in enumerate(results)
            println(lpad(idx,2), ") ($(count_letters(phrase1)) letters) ", rng1, ": \"", join(phrase1," "), "\", ", rng2, ": \"", join(phrase2, " "), "\"")
        end    
    end
    return results
end
