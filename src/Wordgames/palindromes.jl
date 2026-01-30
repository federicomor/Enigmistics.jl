"""
    is_palindrome(s::AbstractString)

Check if a string is palindrome, i.e. if it reads the same backward as forward. 

See also [`scan_for_palindromes`](@ref).

# Examples
```julia-repl
julia> is_palindrome("Oozy rat in a sanitary zoo")
true

julia> is_palindrome("Alle carte t'alleni nella tetra cella")
true
```
"""
function is_palindrome(s::AbstractString)
    i = firstindex(s); j = lastindex(s)
    while i < j
        ci = s[i]; cj = s[j]
        if !isletter(ci)
            i = nextind(s, i)
            continue
        end
        if !isletter(cj)
            j = prevind(s, j)
            continue
        end
        lowercase(normalize_accents(ci)) != lowercase(normalize_accents(cj)) && return false
        i = nextind(s, i); j = prevind(s, j)
    end
    return true
end


# is_palindrome("Never odd or even.")
# @time is_palindrome("ànna")
# @time is_palindrome("ana")
# @time is_palindrome("Oozy rat in a sanitary zoo")
# @time is_palindrome("Alle carte t'alleni nella tetra cella")

"""
```
scan_for_palindromes(text::String; 
    min_length_letters=6, max_length_letters=30, print_results=false)
```

Scan a text and look for pairs of word sequences which are anagrams.
    
Return a vector of matches in the form `(matching_range, matching_string)`.
 
# Arguments
- `text`: the input text to scan
- `min_length_letters=6`: consider only sequences of words with at least this number of letters
- `max_length_letters=30`: consider only sequences of words with at most this number of letters
- `print_results=false`: whether to print results or just return them

See also [`is_palindrome`](@ref).

# Examples
```julia-repl
julia> text = clean_read("../texts/ulyss.txt", newline_replace="/");

julia> scan_for_palindromes(text,  min_length_letters=10)
5-element Vector{Any}:
 (266056:266070, "Madam, I'm Adam")
 (266077:266101, "Able was I ere I saw Elba")
 (266082:266096, "was I ere I saw")
 (1120093:1120105, "Hohohohohohoh")
 (1424774:1424785, "tattarrattat")
```
"""
function scan_for_palindromes(text::String;
                            min_length_letters::Int=6, 
                            max_length_letters::Int=30,
                            print_results::Bool=false)

    # Precompute words and positions
    matches = collect(eachmatch(r"\p{L}+", text))
    words = [m.match for m in matches]
    starts = [m.offset for m in matches]
    ends = [m.offset + lastindex(m.match) - 1 for m in matches]

    n = length(words)
    results = []
    p = Progress(n, desc="Scanning for palindromes...")

    for i in 1:n
        for j in i:n
            # Extract substring from original text
            phrase = text[starts[i]:ends[j]]
            len = count_letters(phrase)

            if len > max_length_letters
                break
            end
            if len >= min_length_letters
                if is_palindrome(phrase)
                    push!(results, (starts[i]:ends[j], phrase))
                end
            end
        end
        next!(p)
    end

    if print_results
        println("Palindromes found:")
        if length(results) == 0
            println("(none)")
        end
        for (idx, (rng, phrase)) in enumerate(results)
            println(lpad(idx, 2), ") ($(count_letters(phrase)) chars) ", rng, ": ", phrase)
        end
    end

    return results
end

# text = clean_read("texts/ulyss.txt", newline_replace="/"); text[1:100]
# text = text[1:500_000]
# @time scan_for_palindromes(text, min_length_letters=10, print_results=true)
# snip(text,266082:266096,30)