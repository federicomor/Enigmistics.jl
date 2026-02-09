
"""
    Slot

Structure for a crossword slot, i.e. a place where a word can be placed.

# Fields
- `row::Int`, `col::Int`: slot position
- `direction::Symbol`: slot direction (`:horizontal` or `:vertical`)
- `length::Int`: slot length
- `pattern::String`: slot pattern, describing letters or blank spaces in its cells
- `flexible_start::Bool`: can this slot be potentially expanded at the start (e.g. is it at the border of the grid)?
- `flexible_end::Bool`: can this slot be potentially expanded at the end (e.g. is it at the border of the grid)?
"""
mutable struct Slot
    row::Int
    col::Int
    direction::Symbol   # :horizontal or :vertical
    length::Int
    pattern::String    # e.g. "C.T", "..A.."
    flexible_start::Bool
    flexible_end::Bool # is this slot structurally closed by black cells on both ends or not?
    # to say if we could, if necessary, expand the length of the slot eg if we are at the borders, 
    # and therefore not limited by black cells but only by the current dimensions of the grid
end

function find_horizontal_slots(grid::Matrix{Char})
    nrows, ncols = size(grid)
    slots = Slot[]

    for r in 1:nrows
        c = 1
        while c <= ncols
            # check if cell is the start of a horizontal slot
            if !is_black(grid[r,c]) && (c == 1 || is_black(grid[r,c-1]))
                start = c # candidate starting point
                letters = Char[] # letters in the current candidate slot
                has_empty = false # do we have empty cells along the way?

                # extend the slot until we hit a black cell or border
                while c <= ncols && !is_black(grid[r,c])
                    ch = grid[r,c]
                    push!(letters, ch)
                    has_empty |= is_empty(ch)
                    c += 1
                end
                len = length(letters)
                # consider as real slots candidates spanning at least two cells and with at least one empty 
                if len >= 2 && has_empty
                    flexible_start = start == 1 
                    flexible_end = start+len-1 == ncols
                    pattern = String(map(ch -> ch == EMPTY_CELL ? '.' : ch, letters))
                    push!(slots, Slot(r, start, :horizontal, len, pattern, flexible_start, flexible_end))
                end
            else
                c += 1
            end
        end
    end

    return slots
end

function find_vertical_slots(grid::Matrix{Char})
    nrows, ncols = size(grid)
    slots = Slot[]

    for c in 1:ncols
        r = 1
        while r <= nrows
            # check if cell is the start of a horizontal slot
            if !is_black(grid[r,c]) && (r == 1 || is_black(grid[r-1,c]))
                start = r # candidate starting point
                letters = Char[] # letters in the current candidate slot
                has_empty = false # do we have empty cells along the way?

                # extend the slot until we hit a black cell or border
                while r <= nrows && !is_black(grid[r,c])
                    ch = grid[r,c]
                    push!(letters, ch)
                    has_empty |= is_empty(ch)
                    r += 1
                end
                len = length(letters)
                # consider as real slots candidates spanning at least two cells and with at least one empty 
                if len >= 2 && has_empty
                    # @show start, start+len-1, letters, len
                    flexible_start = start == 1 
                    flexible_end = start+len-1 == nrows
                    pattern = String(map(ch -> ch == EMPTY_CELL ? '.' : ch, letters))
                    push!(slots, Slot(start, c, :vertical, len, pattern, flexible_start, flexible_end))
                end
            else
                r += 1
            end
        end
    end

    return slots
end
"""
    find_constrained_slots(cw::CrosswordPuzzle)

Find all slots (horizontal and vertical) in the crossword puzzle `cw` that are constrained, i.e. that have at least one empty cell and length at least 2 characters.

# Examples
```julia-repl
julia> cw = example_crossword(type="partial")
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ ⋅  I  ⋅  ⋅  ⋅  W │
  └──────────────────┘

julia> find_constrained_slots(cw)
4-element Vector{Slot}:
 Slot(3, 3, :horizontal, 4, "...R", false, true)
 Slot(6, 1, :horizontal, 6, ".I...W", true, true)
 Slot(3, 3, :vertical, 4, ".EE.", false, true)
 Slot(1, 4, :vertical, 4, "D..R", true, false)
```
"""
function find_constrained_slots(cw::CrosswordPuzzle)
    vcat(
        find_horizontal_slots(cw.grid),
        find_vertical_slots(cw.grid)
    )
end

"""
    compute_options_simple(s::Slot)

Compute the number of fitting words for a slot `s` considering its pattern and length.

Return a tuple `(n_options, candidates)`, where `n_options` is the number of fitting words and `candidates` is a vector containing the list of fitting words.

# Examples
```julia-repl
julia> cw = example_crossword(type="partial")
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ ⋅  I  ⋅  ⋅  ⋅  W │
  └──────────────────┘

julia> slots = find_constrained_slots(cw); slots[2]
Slot(6, 1, :horizontal, 6, ".I...W", true, true)

julia> compute_options_simple(slots[2], verbose=true)
- simple fitting, length: 6 => #options: 18
      some are ["billow", "dismaw", "disnew", "jigsaw", "killow", "kirmew", "mildew", "minnow", "pigmew", "pillow"]
```
"""
function compute_options_simple(s::Slot; verbose=false)
    p = s.pattern
    p = '^'*p*'$' # fixing start and end positions, actually not necessary since length is constricted
    out = fitting_words(Regex(lowercase(p)),s.length,s.length)
    n_options = length(out[s.length])
    if verbose println("- simple fitting, length: $(s.length) => #options: $n_options") end
    if verbose println("      $(n_options<=10 ? "they are" : "some are") $(out[s.length][1:min(n_options,10)])") end
    return n_options, out[s.length]
end
"""
    compute_options_split(s::Slot)

Compute the number of fitting words for a slot `s` by simulating the placement of black cells at each internal position of the slot, i.e. possibly splitting the original slot into two smaller slots.

Return a tuple `(n_options, candidates)`, where `n_options` is a dictionary mapping the internal position of the black cell to the number of fitting words, and `candidates` is a dictionary mapping that same key to a tuple of two lists of fitting words (left and right sub-slots).

# Examples
```julia-repl
julia> cw = example_crossword(type="partial")
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ ⋅  I  ⋅  ⋅  ⋅  W │
  └──────────────────┘

julia> slots = find_constrained_slots(cw); slots[2]
Slot(6, 1, :horizontal, 6, ".I...W", true, true)

julia> compute_options_split(slots[2], verbose=true)
- placing a black cell at (6, 1), pattern: /I...W => #options: 7
      they are ["ignaw", "immew", "inbow", "indew", "indow", "inlaw", "inmew"]
- placing a black cell at (6, 3), pattern: .I/..W => #options: 20/53
      some are Left: ["ai", "bi", "di", "fi", "gi", "hi", "ii", "yi", "ji", "ki"]
      some are Right: ["alw", "baw", "bow", "caw", "ccw", "ckw", "cow", "csw", "daw", "dew"]
- placing a black cell at (6, 4), pattern: .I./.W => #options: 212/10
      some are Left: ["aid", "aik", "ail", "aim", "ain", "air", "ais", "ait", "aix", "bib"]
      they are Right: ["aw", "ew", "fw", "hw", "iw", "kw", "mw", "ow", "sw", "xw"]
- placing a black cell at (6, 5), pattern: .I../W => #options: 852
      some are ["aias", "aide", "aids", "aiel", "aile", "ails", "aims", "aine", "ains", "aint"]
```
"""
function compute_options_split(s::Slot; verbose=false)
    pattern = s.pattern
    L = length(pattern)
    n_options = 1
    # key is the position of the black cell (1-based index within the slot)
    n_options_out = Dict{Int, Int}()
    words_out = Dict{Int, Vector{Vector{String}}}()

    # to avoid warning from the simulation
    # Logging.LogLevel(Error)

    for k in 1:L
        # skip if this position already has a fixed letter
        pattern[k] != '.' && continue
        bcell_row, bcell_col = s.row+(k-1)*Int(s.direction==:vertical), s.col+(k-1)*Int(s.direction==:horizontal)
    
        # simulate the placement of a black cell at each internal position    
        place_black_cell!(cw, bcell_row, bcell_col)
        if !is_connected(cw)
            if verbose println("- placing a black cell at ($bcell_row, $bcell_col) would make a disconnect crossword") end
            # directly revert the test placement
            remove_black_cell!(cw, bcell_row, bcell_col)
            continue
        end
        # otherwise we go on with the analysis
        left_pattern = pattern[1:k-1]
        len_left = length(left_pattern)
        right_pattern = pattern[k+1:end]
        len_right = length(right_pattern)

        if k<=2
            out = fitting_words(Regex(lowercase(right_pattern)),len_right,len_right)
            n_options = length(out[len_right])
            if verbose println("- placing a black cell at ($bcell_row, $bcell_col), pattern: $(left_pattern*'/'*right_pattern) => #options: $n_options") end
            if verbose println("      $(n_options<=10 ? "they are" : "some are") $(out[len_right][1:min(n_options,10)])") end
            push!(n_options_out, k => n_options)
            push!(words_out, k => [[""], out[len_right]])
        elseif k>=s.length-1
            # @show left_pattern, len_left
            out = fitting_words(Regex(lowercase(left_pattern)),len_left,len_left)
            n_options = length(out[len_left])
            if verbose println("- placing a black cell at ($bcell_row, $bcell_col), pattern: $(left_pattern*'/'*right_pattern) => #options: $n_options") end
            if verbose println("      $(n_options<=10 ? "they are" : "some are") $(out[len_left][1:min(n_options,10)])") end
            push!(n_options_out, k => n_options)
            push!(words_out, k => [out[len_left], [""]])
        else
            out_right = fitting_words(Regex(lowercase(right_pattern)),len_right,len_right)
            n_right = length(out_right[len_right])
            out_left = fitting_words(Regex(lowercase(left_pattern)),len_left,len_left)
            n_left = length(out_left[len_left])
            n_options = n_left * n_right
            if verbose println("- placing a black cell at ($bcell_row, $bcell_col), pattern: $(left_pattern*'/'*right_pattern) => #options: $n_left/$n_right") end
            if verbose println("      $(n_left<=10 ? "they are" : "some are") Left: $(out_left[len_left][1:min(n_left,10)])") end
            if verbose println("      $(n_right<=10 ? "they are" : "some are") Right: $(out_right[len_right][1:min(n_right,10)])") end
            push!(n_options_out, k => n_options)
            push!(words_out, k => [out_left[len_left], out_right[len_right]])
        end

        # revert the test placement
        remove_black_cell!(cw, bcell_row, bcell_col)
    end
    # restore default level
    # Logging.LogLevel(Info)
    return n_options_out, words_out
end
"""
    compute_options_flexible(s::Slot, k::Int)

Compute the number of fitting words for a slot `s` considering its flexibility at the start and/or at the end, i.e. simulating the potential expansion of `k` cells in length which could happen by enlarging the grid.

Return a tuple `(n_options, candidates)`, where `n_options` is a dictionary mapping the flexibility simulated (increment at the start and/or at the end) to the number of fitting words, and `candidates` is a dictionary mapping that same key to the list of fitting words.

# Examples
```julia-repl
julia> cw = example_crossword(type="partial")
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ ⋅  I  ⋅  ⋅  ⋅  W │
  └──────────────────┘

julia> slots = find_constrained_slots(cw); slots[2]
Slot(6, 1, :horizontal, 6, ".I...W", true, true)

julia> compute_options_flexible(slots[2], 1, verbose=true)
- flexible start/end, increment: (0, 1) => pattern .I...W., length: 7 => #options: 19
      some are ["billowy", "billows", "disgown", "jigsawn", "jigsaws", "midtown", "mildewy", "mildews", "minnows", "pillowy"]
- flexible start/end, increment: (1, 0) => pattern ..I...W, length: 7 => #options: 9
      they are ["pristaw", "rainbow", "thishow", "trishaw", "uniflow", "whincow", "whipsaw", "whitlow", "whittaw"]

julia> compute_options_flexible(slots[2], 2, verbose=true)
- flexible start/end, increment: (0, 2) => pattern .I...W.., length: 8 => #options: 33
      some are ["bilgeway", "billywix", "billowed", "disbowel", "giveaway", "hideaway", "jigsawed", "midtowns", "mildewed", "mildewer"]
- flexible start/end, increment: (1, 1) => pattern ..I...W., length: 8 => #options: 11
      some are ["boildown", "chippewa", "gairfowl", "muirfowl", "rainbowy", "rainbows", "rainfowl", "thindown", "whipsawn", "whipsaws"] 
- flexible start/end, increment: (2, 0) => pattern ...I...W, length: 8 => #options: 3
      they are ["embillow", "splitnew", "splitsaw"]
```
"""
function compute_options_flexible(s::Slot, increment::Int; verbose=false)
    # key is the increment type, so a Tuple{Int,Int} describing (increment_start, increment_end)
    n_options_out = Dict{Tuple{Int,Int}, Int}()
    words_out = Dict{Tuple{Int,Int}, Vector{String}}()
    if s.flexible_start && !s.flexible_end
        k = increment
        p = s.pattern
        p = "."^k*p
        p='^'*p*'$'
        len = s.length+k
        out = fitting_words(Regex(lowercase(p)),len,len)
        n_options = length(out[len])
        if verbose println("- flexible start, increment: ($k, 0) => pattern $(p[2:end-1]), length: $(len) => #options: $n_options") end
        if verbose println("      $(n_options<=10 ? "they are" : "some are") $(out[len][1:min(n_options,10)])") end
        push!(n_options_out, (k,0) => n_options)
        push!(words_out, (k,0) => out[len])
    elseif !s.flexible_start && s.flexible_end
        k = increment
        p = s.pattern
        p = p*"."^k
        p='^'*p*'$'
        len = s.length+k
        out = fitting_words(Regex(lowercase(p)),len,len)
        n_options = length(out[len])
        if verbose println("- flexible end, increment: (0, $k) => pattern $(p[2:end-1]), length: $(len) => #options: $n_options") end
        if verbose println("      $(n_options<=10 ? "they are" : "some are") $(out[len][1:min(n_options,10)])") end
        push!(n_options_out, (0,k) => n_options)
        push!(words_out, (0,k) => out[len])
    elseif s.flexible_start && s.flexible_end
        for k in 0:increment
            p = s.pattern
            p = "."^k*p*"."^(increment-k)
            p='^'*p*'$'
            len = s.length+increment
            out = fitting_words(Regex(lowercase(p)),len,len)
            n_options = length(out[len])
            if verbose println("- flexible start/end, increment: ($k, $(increment-k)) => pattern $(p[2:end-1]), length: $(len) => #options: $n_options") end
            if verbose println("      $(n_options<=10 ? "they are" : "some are") $(out[len][1:min(n_options,10)])") end
            push!(n_options_out, (k,increment-k) => n_options)
            push!(words_out, (k,increment-k) => out[len])
        end
    else
        if verbose println("Slot is not flexible.") end
        return 0, nothing
    end
    return n_options_out, words_out
end
# output: dictionaries with keys (increment_start,increment_end) => values

# function fit_flexible_proposal(s::Slot, increment::Int, choice::String)
    
function compute_options(s::Slot; simple::Bool=true) #, flexible::Bool, flexible_up_to::Int, split::Bool)
    println("$s")

    # fixed size ones
    println("==== STANDARD CASE ============================")
    out = compute_options_simple(s)

    # flexible ones
    if s.flexible_end || s.flexible_start
        println("==== CONSIDERING FLEXIBILITY ============================")
        compute_options_flexible(s, 1)
        compute_options_flexible(s, 2)
        compute_options_flexible(s, 3)
    end

    # with placements of black cells
    println("==== SIMULATING BLACK CELLS ============================")
    compute_options_split(s)
end

# cw = example_crossword(type="partial")
# slots = find_constrained_slots(cw)
# compute_options_simple(slots[2], verbose=true)
# compute_options_split(slots[2], verbose=true)
# compute_options_flexible(slots[2], 1, verbose=true)
# compute_options_flexible(slots[2], 2, verbose=true)

# cd("Crosswords")
# cw = load_crossword("ex_eng.txt")
# remove_word!(cw, "window")
# remove_word!(cw, "vii"); cw
# remove_word!(cw, "seen"); cw
# remove_word!(cw, "narrow"); cw

# find_vertical_slots(cw.grid)
# find_horizontal_slots(cw.grid)
# slots = find_constrained_slots(cw)

# # Logging.disable_logging(Warn)
# compute_options(slots[2]) # 39 101 152
# compute_options(slots[3]) # 12 15 35
# compute_options(slots[4]) # 240 57 687 995

# function fill!(cw::CrosswordPuzzle)
#     # base case
#     if is_full(cw)
#         return true
#     end

#     slots = find_constrained_slots(cw)
#     most_constrained_slot_idx = 0
#     min_n_options = Inf; min_candidates = Dict{Int64, Vector{String}}()
    
#     for i in eachindex(slots)
#         @info "Slot $i: $(slots[i])"
#         n_options, candidates = compute_options_simple(slots[i])
#         if n_options < min_n_options
#             most_constrained_slot_idx = i
#             min_n_options = n_options
#             min_candidates = candidates
#         end
#     end
#     if min_n_options == 0
#         @warn "No candidates found for slot $(slots[most_constrained_slot_idx]), backtracking..."
#         return false
#     else
#     # return most_constrained_slot_idx, min_n_options, min_candidates
#     word_to_be_placed = rand(min_candidates[slots[most_constrained_slot_idx].length])
#     # @info word_to_be_placed
#     place_word!(cw, word_to_be_placed, slots[most_constrained_slot_idx].row, slots[most_constrained_slot_idx].col, slots[most_constrained_slot_idx].direction)

#     fill!(cw)
#     remove_word!(cw, word_to_be_placed)
# end
# fill!(cw)

import Base: fill!
"""
    fill!(cw::CrosswordPuzzle; seed=rand(Int), verbose=false)

Fill the crossword puzzle `cw` using a backtracking algorithm with Minimum Remaining Values (MRV) heuristic.

For now it only uses the simple fitting method ([`compute_options_simple`](@ref)) to compute candidate words for each slot; more advanced methods (flexibility, splitting) will soon be added.

# Examples
```julia-repl
julia> cw = example_crossword(type="partial")
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ ⋅  I  ⋅  ⋅  ⋅  W │
  └──────────────────┘

julia> fill!(cw, seed=80)
true

julia> cw
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  Y  ■  A │
3 │ T  ■  P  E  E  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ P  I  L  L  O  W │
  └──────────────────┘
```
"""
function fill!(cw::CrosswordPuzzle; seed=rand(Int), verbose=false)
    Random.seed!(seed)
    return _fill!(cw; seed=seed, verbose=verbose)
end

function _fill!(cw::CrosswordPuzzle; seed=rand(Int), verbose=false)
    if verbose print("Completeness [%]: $(round(100*sum(cw.grid .!= EMPTY_CELL) / prod(size(cw)),digits=2))\r") end
    # Base case: crossword is complete
    if is_full(cw)
        return true
    end
    
    slots = find_constrained_slots(cw)
    # Select most constrained slot (MRV)
    most_constrained_slot_idx = 0
    min_n_options = Inf
    min_candidates = String[]

    for (i, s) in enumerate(slots)
        n_options, candidates = compute_options_simple(s)
        if n_options == 0
            # println("Dead end at slot $s")
            return false
            # maybe add something here; user can know a "new" word (not in the dictionary) to place
        end
        if n_options < min_n_options
            most_constrained_slot_idx = i
            min_n_options = n_options
            min_candidates = shuffle(candidates)
            # min_candidates = shuffle(candidates[s.length])
            # min_candidates = candidates[s.length]
        end
    end

    slot = slots[most_constrained_slot_idx]

    # Try all candidate words
    for word in min_candidates[1:min(length(min_candidates), 30)]
    # for word in min_candidates
        if place_word!(cw, word, slot.row, slot.col, slot.direction)
            # @info "trying word '$word' at slot $slot"
            if _fill!(cw, verbose=verbose)
                return true # SUCCESS propagates upward
            end
            remove_word!(cw, word) # backtrack
        end
    end

    # All candidates failed
    return false
end

# cw = example_crossword(type="partial")
# fill!(cw, seed=80)
# cw

# with_logger(NullLogger()) do
    # fill!(cw, seed=80)
    # display(cw)
# end
# clear!(cw, deep=false)

# cw = patterned_crossword(6,8)
# cw = patterned_crossword(8,10, max_density = 0.2)
# cw = patterned_crossword(10,14, symmetry=true)
# cw = striped_crossword(10,14, min_stripe_dist = 4, keep_stripe_prob = 0.9)





# cw = patterned_crossword(8,10)
# @time with_logger(NullLogger()) do
#     seed = rand(Int)
#     # seed = 1666050086924584950
#     println("seed: $seed")
#     fill!(cw, seed=seed, verbose=true)
#     cw
# end
# clear!(cw)




# cw = striped_crossword(10,14, min_stripe_dist = 4, keep_stripe_prob = 0.9)
# @time with_logger(NullLogger()) do
#     fill!(cw, verbose=true); cw
# end


# cw = patterned_crossword(10,12, symmetry=true)
# @time with_logger(NullLogger()) do
#     fill!(cw, verbose=true); cw
# end





# # Simple example of using carriage return to overwrite output
# for i in 1:10
#     print("Progress: $i/10\n") # Print progress and return to the start of the line
#     print("altra riga di test $(i^2)\n")
#     print("\033[2d")
#     sleep(0.5) # Simulate time-consuming task
# end
# println("Done!") # Move to the next line after completion







# cw = striped_crossword(10,14, min_stripe_dist = 4, keep_stripe_prob = 0.8)
# @time with_logger(NullLogger()) do
#     seed = rand(Int)
#     println("seed: $seed")
#     fill!(cw, seed=seed, verbose=true)
#     cw
# end



# LogLevel(Info)



# cw = patterned_crossword(9,12, symmetry=true)
# @time with_logger(NullLogger()) do
#     seed = rand(Int)
#     println("seed: $seed")
#     fill!(cw, seed=seed, verbose=true)
#     cw
# end

# cw = patterned_crossword(10, 8, symmetry=true, seed = rand(1:1_000))
# cw = striped_crossword(8, 10, symmetry=true, seed = rand(1:1_000))
# # cw = patterned_crossword(6, 6, symmetry=true, seed = rand(1:1_000))
# cw = patterned_crossword(6, 6, symmetry=true, seed = 48)
# cw = patterned_crossword(6, 8, symmetry=true, seed = 7)
# place_word!(cw, "Julia", 3, 2, :horizontal); cw
# seed = rand(1:1000); @info seed; fill!(cw,   seed = seed); cw


# cw = striped_crossword(8, 10, symmetry=true, seed = 555)
# place_word!(cw, "Julia", 4, 6, :horizontal); cw
# # place_word!(cw, "Lang", 5, 1, :horizontal); cw
# fill!(cw, seed = 1)
# cw