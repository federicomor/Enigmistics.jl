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
    clean_text(s::AbstractString; newline_replace=" ")

Take a string and return a cleaned up version of it.

This allows to work better with the functions of the Enigmistics module. For example: multiple occurrences of newlines, spaces, or tabs get reduced to a single space (newlines information can be preserved by setting a different character in `newline_replace`). 

It's the function on which [`clean_read`](@ref) relies on.
"""
function clean_text(s::AbstractString; newline_replace=" ")
    s_clean = s |> 
        x -> normalize_accents(x) |>
        x -> replace(x, "\n|\t" => " ") |> # convert new lines to spaces
        x -> replace(x, r" {2,}" => " $newline_replace ") |> # so that when there are more spaces it means that there was a newline
        x -> replace(x, r" {2,}" => " ") # and finally adjust multiple spaces to a single one
    return s_clean
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
            w->replace(w, r"[^a-z]" => " ") |> 
            w->replace(w,r" {2,}" => " ") |> 
            w->replace(w, r"^\s+|\s+$" => "")
end
# strip_text("This? is a -very simple- test!! nòw morè còmplèx")


# filename = joinpath(@__DIR__,"../texts/commedia.txt")
# filename = joinpath(@__DIR__,"../texts/paradiselost.txt")

# text=readlines(filename)[1:20] # original file
# clean_text(join(text,"\n"),newline_replace="")

# join(readlines(filename), "\n")[1:104]

# clean_read(filename)[1:98]
# clean_read(filename, newline_replace="/")[1:98]

# s = join(readlines(filename), "\n")[1:104]
# @show s
# clean_text(s,newline_replace="/")

"""
    count_letters(s::AbstractString)

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
function count_letters(s::AbstractString)
    return sum(isletter.(char for char in s))
end
function count_letters(s::AbstractVector)
    return sum(count_letters.(s))
end

# s = "This sentence has sixty-four alphabetic characters and 10 non alphabetic ones!" 
# s = "This sentence has thirty-one letters" 
# count_letters(s) # 31
# length(s) # 36 = 31 + 4 spaces + 1 hyphen


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
    # @show real_start real_end
    return text[real_start:real_end]
end

# text = "abcdefghijklmnopqrstuvwxyz";
# snip(text,13:14,0)
# snip(text,13:14,4)
