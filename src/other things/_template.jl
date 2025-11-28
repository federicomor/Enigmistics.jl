"""
    
# Examples
```julia-repl

```
"""
function is_pangram(s::AbstractString; language="en", verbose=false)
    alphabet = language_corrections[language]
    s_set = Set(lowercase.(collect(s)))
    for char in alphabet
        # if a character in the alphabet is missing from the string then it is not a pangram
        if char ∉ s_set
            if verbose @info "Missing character: $char" end
            return false
        end
    end
    return true
end

"""

# Examples
```julia-repl

```
"""
function scan_for_pangrams(s::AbstractString, max_length_letters=52; language="en", verbose=false) 
    # words pool non serve, semplicmente aggiungi una parola in coda o rimuovila all'inizio se la lunghezza del pool supera le lettere massime consentite
    # crea un dizionario con gli "a capo" per tenere traccia di quando comincia o finisce una nuova riga
    # in corrispondenza di quale parola
    pool = Vector{String}()
    words = split(s, " ")
    for w in words
        push!(pool, w)
        while sum(count_letters(word) for word in pool) > max_length_letters && length(pool)>=2
            popfirst!(pool)
        end
        if !isempty(pool)
            candidate = join(pool, " ")
            
            if is_pangram(candidate, language=language, verbose=verbose)
                println("$(sum(isletter.(char for char in candidate))) letters ($(length(candidate)) chars): ", candidate)
                # println("$(sum(isletter.(char for char in candidate))) letters ($(length(candidate)) chars): ", repr(candidate))
            end
        end
    end
end
