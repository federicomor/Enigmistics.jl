function setup_dictionary(language="en")
    dictionary = Vector{String}()
    if language=="it"
        dictionary = readlines(joinpath(@__DIR__,"dictionaries/italian.txt"))
    elseif language=="en"
        dictionary = readlines(joinpath(@__DIR__,"dictionaries/english.txt"))
    end

    lengths = length.(dictionary)
    extrema(lengths)
    words = Dict{Int,Vector{String}}()
    for i in 2:21
        words[i] = copy(dictionary[lengths .== i])
    end
    return words
end

# words = setup_dictionary("it")
words = setup_dictionary("en")

function fitting_words(pattern::Regex, min_len::Int, max_len::Int)
    results = Dict{Int,Vector{String}}()
    for len in min_len:max_len
        results[len] = filter(w -> occursin(pattern,w), get(words,len,String[]))
    end
    return results
end
function fitting_words(pattern::String, min_len::Int, max_len::Int)
    pattern = Regex(pattern)
    return fitting_words(pattern, min_len, max_len)
end

# fitting_words("...the",6,6)
# fitting_words(r"...the",6,6)
# fitting_words(r"see.",6,6)
# fitting_words(Regex("...the"),6,6)

# fitting_words(r"^a.a$", 3, 5)
# fitting_words(r"^a.*a$", 3, 5) 
