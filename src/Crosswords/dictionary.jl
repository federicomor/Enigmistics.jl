function setup_dictionary(language::String="en")
    filename =
        language == "it" ? "italian.txt" :
        language == "en" ? "english.txt" :
        error("Unsupported language: $language")

    path = joinpath(@__DIR__, "dictionaries", filename)
    dictionary = readlines(path)

    lengths = length.(dictionary)
    max_len = maximum(lengths)
    words = Dict{Int,Vector{String}}()
    for i in 2:max_len
        words[i] = dictionary[lengths .== i]
    end
    return words
end

const DICTIONARY_WORDS = Dict{Int,Vector{String}}()
"""
    set_dictionary(language="en")

Load the dictionary associated to the specified language. 

Current supported languages are 
- "en", english
- "it", italian. 
"""
function set_dictionary(language::String="en")
    empty!(DICTIONARY_WORDS)
    merge!(DICTIONARY_WORDS, setup_dictionary(language))
    return DICTIONARY_WORDS
end
set_dictionary("en")

"""
    fitting_words(pattern::Regex, min_len::Int, max_len::Int)
    fitting_words(pattern::String, min_len::Int, max_len::Int)

Given a pattern and a range of word lengths, return a dictionary mapping each length to the list of matching words having that pattern and length.

# Examples
```julia-repl
julia> pattern="^pe.*ce\$"
"^pe.*ce\$"

julia> fitting_words(pattern, 5, 8)
Dict{Int64, Vector{String}} with 4 entries:
  5 => ["peace", "pence"]
  6 => ["pearce"]
  7 => ["penance", "pentace", "pentice"]
  8 => ["perforce"]

julia> set_dictionary("it");

julia> fitting_words(pattern, 5, 8)
Dict{Int64, Vector{String}} with 4 entries:
  5 => ["pence", "pesce"]
  6 => ["pedace", "pedice", "penice"]
  7 => ["pendice", "pennace", "perisce", "pernice"]
  8 => ["pellacce", "pellicce", "pennucce", "pezzacce"]
```
"""
function fitting_words(pattern::Regex, min_len::Int, max_len::Int)
    results = Dict{Int,Vector{String}}()
    for len in min_len:max_len
        results[len] = filter(w -> occursin(pattern,w), get(DICTIONARY_WORDS,len,String[]))
    end
    return results
end
function fitting_words(pattern::String, min_len::Int, max_len::Int)
    pattern = Regex(pattern)
    return fitting_words(pattern, min_len, max_len)
end