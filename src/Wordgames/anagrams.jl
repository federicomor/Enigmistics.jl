"""
    are_anagrams(s1::AbstractString, s2::AbstractString; be_strict=true, skip_checks=false)

Check if two strings are anagrams, i.e. if the letters of one can be rearranged to form the other.

The parameter `be_strict` is defaulted to `true` to avoid considering as anagrams strings where one is simply a permutation of the other, while `skip_checks` can be set to `true` to avoid the preliminary operations about lengths checks and characters normalization.

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
function are_anagrams(s1::AbstractString,s2::AbstractString; be_strict=true, skip_checks=false)
    if skip_checks
        s1_clean = s1
        s2_clean = s2
    else 
        s1_clean = lowercase.(filter(isletter,collect(s1)))
        s2_clean = lowercase.(filter(isletter,collect(s2)))
        length(s1_clean) != length(s2_clean) && return false
    end
    # for c in Set(s1_clean)
    #     if count(x->x==c,s1_clean) != count(x->x==c,s2_clean)
    #         return false
    #     end
    # end
    freq = Dict{Char, Int}()
    for c in s1_clean
        freq[c] = get(freq, c, 0) + 1
    end
    for c in s2_clean
        freq[c] = get(freq, c, 0) - 1
    end
    any(v != 0 for v in values(freq)) && return false
    if be_strict
        # derive the words, sort them and compare the result
        s1_cleaner = strip_text(s1)
        s2_cleaner = strip_text(s2)
        # @show s1_cleaner
        # @show s2_cleaner
        return sort(split(s1_cleaner," ")) != sort(split(s2_cleaner," "))
    end
    return true
end
function are_anagrams(s1::Vector,s2::Vector; be_strict=false, skip_checks=false)
    return are_anagrams(join(s1, " "),join(s2, " "),be_strict=be_strict,skip_checks=skip_checks)
end

# are_anagrams("The Morse Code","Here come dots!") # true anagram
# are_anagrams("The Morse Code","Morse: the code!") # just a fancy reordering
# are_anagrams("The Morse Code","Morse: the code!", be_strict=false)
are_anagrams("a","a", be_strict=false)



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
```jldoctest-
julia> text = "Last night I saw a gentleman; he was a really elegant man.";

julia> matches = scan_for_anagrams(text, min_length_letters=1, max_length_letters=14, max_distance_words=10, be_strict=false)
4-element Vector{Any}:
 (14:16, ["saw"], 34:36, ["was"])
 (14:18, ["saw", "a"], 34:38, ["was", "a"])
 (18:18, ["a"], 38:38, ["a"])
 (18:28, ["a", "gentleman"], 47:57, ["elegant", "man"])

julia> matches = scan_for_anagrams(text, min_length_letters=1, max_length_letters=14, max_distance_words=10, be_strict=true)
3-element Vector{Any}:
 (14:16, ["saw"], 34:36, ["was"])
 (14:18, ["saw", "a"], 34:38, ["was", "a"])
 (18:28, ["a", "gentleman"], 47:57, ["elegant", "man"])

julia> matches = scan_for_anagrams(text, min_length_letters=5, max_length_letters=14, max_distance_words=10)
1-element Vector{Any}:
 (18:28, ["a", "gentleman"], 47:57, ["elegant", "man"])
```
"""
function scan_for_anagrams(text::String;
                            min_length_letters::Int=6, 
                            max_length_letters::Int=20,
                            max_distance_words::Int=20,
                            print_results=false, be_strict=true)

    # precompute words and positions
    matches = collect(eachmatch(r"\w+", text))
    words = [m.match for m in matches]
    words = lowercase.(filter.(x->isletter(x),words))
    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]

    n = length(words)
    results = []

    p = Progress(n, desc="Scanning for anagrams...")

    for i in 1:n
        for j in i:n
            pool1 = words[i:j]
            len1 = sum(count_letters(w) for w in pool1)
            if len1 > max_length_letters
                break
            end
            if len1 >= min_length_letters
                # look ahead for pool2
                for k in (j+1):min(n, j+max_distance_words)
                    for l in k:n
                        pool2 = words[k:l]
                        len2 = sum(count_letters(w) for w in pool2)
                        if len2 > max_length_letters
                            break
                        end
                        if len2 >= min_length_letters && len1==len2
                            if are_anagrams(pool1, pool2; be_strict=be_strict, skip_checks=true)
                                # character spans from original text
                                rng1 = starts[i]:ends[j]
                                rng2 = starts[k]:ends[l]
                                # phrase1 = text[rng1]
                                # phrase2 = text[rng2]
                                # push!(results, (rng1, phrase1, rng2, phrase2))
                                push!(results, (rng1, pool1, rng2, pool2))
                            end
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
            println(lpad(idx,2), ") ($(count_letters(phrase1)) letters) ", rng1, ": ", join(phrase1," "), ", ", rng2, ": ", join(phrase2, " "))
        end    
    end

    return results
end

# text = "Last night I saw a gentleman; he was a really elegant man.";
# matches = scan_for_anagrams(text, min_length_letters=1, max_length_letters=14, max_distance_words=10,print_results=true)
# matches = scan_for_anagrams(text, min_length_letters=1, max_length_letters=14, max_distance_words=10, be_strict=true)
# matches = scan_for_anagrams(text, min_length_letters=5, max_length_letters=14, max_distance_words=10)

# text = clean_read("../texts/paradise_lost.txt", newline_replace="/"); text[1:100]
# out = @timev scan_for_anagrams(text, min_length_letters=5, max_length_letters=14, max_distance_words=10, 
#     be_strict=true, print_results=true)