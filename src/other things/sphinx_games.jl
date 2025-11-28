"""
    find_consonant_changes(text, k=1; min_length_letters=3)

Find pairs of words in `text` that differ only by at most `k` consonant substitutions, i.e. with vowels remaining fixed.
# Examples
```julia-repl
julia> find_consonant_changes("The bad cat sat")
1-element Vector{Any}:
 ("cat", "sat")

julia> find_consonant_changes("The bad cat sat", 2)
3-element Vector{Any}:
 ("bad", "cat")
 ("bad", "sat")
 ("cat", "sat")
```
"""
function are_consonant_changes(s1::AbstractString, s2::AbstractString; max_diff = 1)
    s1_clean = strip_text(s1)
    s2_clean = strip_text(s2)
    if length(s1_clean) == length(s2_clean)
        valid = true
        cases = 0
        for k in eachindex(s1_clean)
            if s1_clean[k] != s2_clean[k]
                cases += 1
                valid &= s1_clean[k] in CONSONANTS && s2_clean[k] in CONSONANTS
            end
        end
        if valid && cases <= max_diff && s1_clean!=s2_clean
            return true
        end
    end
    return false
end

function are_consonant_changes(s1::Vector, s2::Vector; max_diff = 1)
    return are_consonant_changes(join(s1, " "),join(s2, " "),max_diff=max_diff)
end

# @assert are_consonant_changes("cat"," sat") == true
# @assert are_consonant_changes(["cat"],[" sat"]) == true
# @assert are_consonant_changes("cat"," sat") == true
# @assert are_consonant_changes("passo","pasto") == true


function are_vowel_changes(s1::AbstractString, s2::AbstractString; max_diff = 1, force_last_letters_equal=false)
    s1_clean = strip_text(s1)
    s2_clean = strip_text(s2)
    if length(s1_clean) == length(s2_clean)
        valid = true
        cases = 0
        for k in eachindex(s1_clean)
            if s1_clean[k] != s2_clean[k]
                cases += 1
                valid &= s1_clean[k] in VOWELS && s2_clean[k] in VOWELS
            end
        end
        # @show s1_clean, s2_clean, cases, valid
        # if force_last_letters_equal=true, we check that last letters are true to avoid (at least in italian) word games produced by plural
        # valid &= s1_clean[end] == s2_clean[end] || !force_last_letters_equal
        if force_last_letters_equal 
            for w1 in split(s1_clean," "), w2 in split(s2_clean," ")
                valid &= w1[end] == w2[end] 
            end
        end
        if valid && cases <= max_diff && s1_clean!=s2_clean
            return true
        end
    end
    return false
end
function are_vowel_changes(s1::Vector, s2::Vector; max_diff = 1,force_last_letters_equal=false)
    return are_vowel_changes(join(s1, " "),join(s2, " "),max_diff=max_diff,force_last_letters_equal=force_last_letters_equal)
end

# are_vowel_changes("letter","latter")
# are_vowel_changes("pane","pani")
# are_vowel_changes("pane","pani", force_last_letters_equal=true)
# strip_text(s1)
# s1, s2 = "pere", "pera"
# s1, s2 = "e quali", "o quali"
# s1, s2 = "suo veramente", "sua veramente"
# s1, s2 = "le loro", "li loro"
# are_vowel_changes(s1,s2)
# are_vowel_changes(s1,s2,force_last_letters_equal=true)

"""
    find_vowel_changes(text; max_diff=1, min_length_letters=3)

Find pairs of words in `text` that differ only by at most `k` vowel substitutions, i.e. with consonants remaining fixed.

# Examples
```julia-repl
julia> find_vowel_changes("In the latter letter...")
1-element Vector{Any}:
 ("latter", "letter")
```
"""

function find_vowel_changes(text::String;
                            max_diff = 1, force_last_letters_equal=false,
                            min_length_letters::Int=3, 
                            max_length_letters::Int=30,
                            max_distance_words::Int=50,
                            print_results=false, be_strict=false)

    # Precompute words and positions
    matches = collect(eachmatch(r"\w+", text))
    words = [m.match for m in matches]
    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]

    n = length(words)

    results_vowel_changes = []

    p = Progress(n, desc="Scanning for vowel changes...")

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
                            if are_vowel_changes(pool1, pool2, max_diff=max_diff, force_last_letters_equal=force_last_letters_equal)
                                # character spans from original text
                                rng1 = starts[i]:ends[j]
                                rng2 = starts[k]:ends[l]
                                push!(results_vowel_changes, (rng1, pool1, rng2, pool2))
                            end
                        end
                    end
                end
            end
        end
        next!(p)
    end

    if print_results
        println("Vowel changes found:")
        for (idx, (rng1, phrase1, rng2, phrase2)) in enumerate(results_vowel_changes)
            println(lpad(idx,2), ") ", rng1, ": ", join(phrase1, " "), ", ", rng2, ": ", join(phrase2, " "))
        end    
    end

    return results_vowel_changes
end


function find_consonant_changes(text::String;
                            max_diff = 1,
                            min_length_letters::Int=3, 
                            max_length_letters::Int=30,
                            max_distance_words::Int=50,
                            print_results=false, be_strict=false)

    # Precompute words and positions
    matches = collect(eachmatch(r"\w+", text))
    words = [m.match for m in matches]
    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]

    n = length(words)

    results_consonant_changes = []

    p = Progress(n, desc="Scanning for consonant changes...")

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
                            if are_consonant_changes(pool1, pool2, max_diff=max_diff)
                                # character spans from original text
                                rng1 = starts[i]:ends[j]
                                rng2 = starts[k]:ends[l]
                                push!(results_consonant_changes, (rng1, pool1, rng2, pool2))
                            end
                        end
                    end
                end
            end
        end
        next!(p)
    end

    if print_results
        println("Consonant changes found:")
        for (idx, (rng1, phrase1, rng2, phrase2)) in enumerate(results_consonant_changes)
            println(lpad(idx,2), ") ", rng1, ": ", join(phrase1, " "), ", ", rng2, ": ", join(phrase2, " "))
        end    
    end

    return results_consonant_changes
end


text = clean_read("../texts/promessi_sposi.txt", newline_replace="/"); text[1:100]
text = clean_read("../texts/paradise_lost.txt", newline_replace="/"); text[1:100]
out3 = find_vowel_changes(text[100_000:200_000], min_length_letters=6, max_distance_words=10, force_last_letters_equal=true)
out3 = find_consonant_changes(text[100_000:200_000], min_length_letters=6, max_distance_words=20)

# out = scan_for_anagrams(text, be_strict=true)
# out = scan_for_pangrams(text, max_length_letters=48, language="it")
# out = scan_for_palindromes(text)
# out = scan_for_heterograms(text,min_length_letters=13)
# out = scan_for_lipograms(text,"ae")