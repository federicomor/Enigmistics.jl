# const CONSONANTS = collect("bcdfghjklmnpqrstvwxyz")
# const VOWELS = collect("aeiou")

const EN_ALPHABET = collect('a':'z')
const IT_ALPHABET = setdiff(EN_ALPHABET,collect("jkxyw"))

const language_corrections = Dict{String,Vector{Char}}(
    "en" => EN_ALPHABET,
    "it" => IT_ALPHABET
)

const alphabet_index = Dict(
    lang => Dict(c => i for (i, c) in enumerate(chars))
    for (lang, chars) in language_corrections
)

const ACCENT_RULES = Dict(
    'à' => 'a','á' => 'a','â' => 'a','ä' => 'a',
    'é' => 'e','è' => 'e','ê' => 'e','ë' => 'e',
    'ì' => 'i','í' => 'i','î' => 'i','ï' => 'i',
    'ò' => 'o','ó' => 'o','ô' => 'o','ö' => 'o',
    'ù' => 'u','ú' => 'u','û' => 'u','ü' => 'u'
)
normalize_accents(w::AbstractString) = replace(w::AbstractString, ACCENT_RULES...)
normalize_accents(c::AbstractChar) = get(ACCENT_RULES, c, c)