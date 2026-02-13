"""
    clean_text(s::AbstractString; newline_replace=" ")

Take a string and return a cleaned up version of it.

This allows to work better with the functions of the Enigmistics module. For example: multiple occurrences of newlines, spaces, or tabs get reduced to a single space (newlines information can be preserved by setting a different character in `newline_replace`). 

It's the function on which [`clean_read`](@ref) relies on.
"""
function clean_text(s::AbstractString; newline_replace=" ")
    s_clean = s |> 
        # x -> normalize_accents(x) |>
        x -> replace(x, "\n|\t" => " ") |> # convert new lines to spaces
        x -> replace(x, r" {2,}" => " $newline_replace ") |> # so that when there are more spaces it means that there was a newline
        x -> replace(x, r" {2,}" => " ") # and finally adjust multiple spaces to a single one
    return s_clean
end


"""
    clean_read(filename::AbstractString; newline_replace=" ")

Read a text file and return a string containing its contents.

The returned string is cleaned up to work better with the functions of the Enigmistics module. For example: multiple occurrences of newlines, spaces, or tabs get reduced to a single space (newlines information can be preserved by setting a different character in `newline_replace`). 

# Examples
```julia-repl
julia> readlines("../texts/commedia.txt")[1:9] # simple read
9-element Vector{String}:
 "LA DIVINA COMMEDIA"
 "di Dante Alighieri"
 "INFERNO"
 ""
 ""
 ""
 "Inferno: Canto I"
 ""
 "  Nel mezzo del cammin di nostra vita"

julia> join(readlines(filename), " ")[1:107] # simple read + join
"LA DIVINA COMMEDIA di Dante Alighieri      INFERNO  Inferno: Canto I    Nel mezzo del cammin di nostra vita"

julia> clean_read(filename)[1:98] # clean read
"LA DIVINA COMMEDIA di Dante Alighieri INFERNO Inferno: Canto I Nel mezzo del cammin di nostra vita"

julia> clean_read(filename, newline_replace="/")[1:104] # clean read + newline replacement
"LA DIVINA COMMEDIA di Dante Alighieri / INFERNO / Inferno: Canto I / Nel mezzo del cammin di nostra vita"
```
"""
function clean_read(filename::AbstractString; newline_replace=" ")
    s = join(readlines(filename)," ") 
    # s = s |> x -> replace(x, r" +" => " ") |> x -> replace(x, r"\n+" => "\n")
    return clean_text(s,newline_replace=newline_replace)
end


"""
    strip_text(text)

Normalize a text by converting it to lowercase, removing all non-alphabetic characters, and stripping leading/trailing spaces.

# Examples
```julia-repl
julia> strip_text("This? is a -very simple, indeed- test!!")
"this is a very simple indeed test"
```
"""
function strip_text(s::AbstractString)
    return lowercase(s) |> 
            w->normalize_accents(w) |>
            w->replace(w, r"[^a-z]" => " ") |> # keep only letters a-z, replace others with space
            w->replace(w,r" {2,}" => " ") |> # reduce multiple spaces to single one
            w->replace(w, r"^\s+|\s+$" => "") # strip leading/trailing spaces
end
strip_text(c::Char) = strip_text(string(c)) 


"""
    count_letters(s::AbstractString)
    count_letters(s::Vector{AbstractString})

Count the number of alphabetic characters in a string.

# Examples
```julia-repl
julia> s = "This sentence has thirty-one letters";

julia> count_letters(s) # 31
31

julia> length(s) # 36 = 31 letters + 4 spaces + 1 hyphen
36
```
"""
count_letters(s::AbstractString) = count(isletter, s)
count_letters(s::AbstractVector{<:AbstractString}) = sum(count_letters, s)

# function count_letters(s::AbstractString)
#     # return sum(isletter.(char for char in s))
#     count(isletter, s)
# end
# function count_letters(s::Vector{AbstractString})
#     return sum(count_letters.(s))
# end


"""
    snip(text::String, interval::UnitRange{Int}, pad=10)

Extract a snippet of text from a given range, enlarged on both sides by the given padding.

# Examples
```julia-repl
julia> text = "abcdefghijklmnopqrstuvwxyz";

julia> snip(text,13:14,0)
"mn"

julia> snip(text,13:14,2)
"klmnop"
```
"""
function snip(text::String, rng::UnitRange{Int}, pad=10)
    real_start = max(1,rng.start-pad) 
    real_end = min(length(text),rng.stop+pad) 
    return text[real_start:real_end]
end

# text = "abcdefghijklmnopqrstuvwxyz";
# snip(text,13:14,0)
# snip(text,13:14,4)


"""
    highlight_letter(s::AbstractString, letters::AbstractString)
    highlight_letter(s::AbstractString, letter::AbstractChar)

Highlight in the string `s` all occurrences of the letters in `letters` (or the single `letter`), by printing them in a bold and coloured font.
"""
function highlight_letter(s::AbstractString, letters::AbstractString)
    s = strip_text(s)
    letters = strip_text(letters)
    for c in s
        if occursin(c,letters)
            printstyled(c, underline=false, bold=true, color=:magenta)
        else
            print(c)
        end
    end
end
highlight_letter(s::AbstractString, letter::AbstractChar) = highlight_letter(s::AbstractString, string(letter))
