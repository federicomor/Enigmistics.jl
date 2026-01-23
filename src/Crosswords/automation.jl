
"""
    Slot

Structure for a crossword slot, i.e. a place where a word can be placed.

# Fields
- `row`, `col`: slot position
- `direction`: slot direction, :horizontal or :vertical
- `length`: slot length
- `pattern`: slot pattern, describing letters or blank spaces in the slot cells (e.g. "C.T" or "..A..")
- `flexible_start`: can this slot be potentially expanded at the start (i.e. is it at the border of the grid)?
- `flexible_end`: can this slot be potentially expanded at the end (i.e. is it at the border of the grid)?
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

Find all slots (horizontal and vertical) in the crossword puzzle `cw` that are constrained, i.e. that have at least one empty cell and length at least 2.

# Examples
```julia-repl
julia> cw
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  O  ■  ⋅ │
3 │ T  ■  S  O  U  R │
4 │ E  V  E  R  ■  ⋅ │
5 │ ■  I  E  ■  ■  ⋅ │
6 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
  └──────────────────┘

julia> find_constrained_slots(cw)
4-element Vector{Slot}:
 Slot(6, 1, :horizontal, 6, "......", true, true)
 Slot(4, 2, :vertical, 3, "VI.", false, true)
 Slot(3, 3, :vertical, 4, "SEE.", false, true)
 Slot(1, 6, :vertical, 6, "N.R...", true, true)
```
"""
function find_constrained_slots(cw::CrosswordPuzzle)
    vcat(
        find_horizontal_slots(cw.grid),
        find_vertical_slots(cw.grid)
    )
end


function compute_options_simple(s::Slot)
    p = s.pattern
    p = '^'*p*'$' # fixing start and end positions, actually not necessary since length is constricted
    out = fitting_words(Regex(lowercase(p)),s.length,s.length)
    n_options = length(out[s.length])
    @info "- length: $(s.length) => #options: $n_options"
    @info "\t $(out[s.length][1:min(n_options,10)])"
    return n_options, out
end
function compute_options_split(s::Slot)
    pattern = s.pattern
    L = length(pattern)
    n_options = 1; out = Dict{Int64, Vector{String}}()

    # to avoid warning from the simulation
    # Logging.LogLevel(Error)

    for k in 1:L
        # skip if this position already has a fixed letter
        pattern[k] != '.' && continue
        bcell_row, bcell_col = s.row+(k-1)*Int(s.direction==:vertical), s.col+(k-1)*Int(s.direction==:horizontal)
    
        # simulate the placement of a black cell at each internal position    
        place_black_cell!(cw, bcell_row, bcell_col)
        if !is_connected(cw)
            println("- placing a black cell at ($bcell_row, $bcell_col) would make a disconnect crossword")
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
            println("- placing a black cell at ($bcell_row, $bcell_col) => k: $k, pattern: $(left_pattern*'/'*right_pattern) => #options: $n_options")
            println("\t ", out[len_right][1:min(n_options,10)])
        elseif k>=s.length-1
            # @show left_pattern, len_left
            out = fitting_words(Regex(lowercase(left_pattern)),len_left,len_left)
            n_options = length(out[len_left])
            println("- placing a black cell at ($bcell_row, $bcell_col) => k: $k, pattern: $(left_pattern*'/'*right_pattern) => #options: $n_options")
            println("\t ", out[len_left][1:min(n_options,10)])
        else
            out_right = fitting_words(Regex(lowercase(right_pattern)),len_right,len_right)
            n_right = length(out_right[len_right])
            out_left = fitting_words(Regex(lowercase(left_pattern)),len_left,len_left)
            n_left = length(out_left[len_left])
            n_options = n_left * n_right
            println("- placing a black cell at ($bcell_row, $bcell_col) => k: $k, pattern: $(left_pattern*'/'*right_pattern) => #options: $n_options")
            println("\t Left: ", out_left[len_left][1:min(n_left,5)])
            println("\t Right: ", out_right[len_right][1:min(n_right,5)])
        end

        # revert the test placement
        remove_black_cell!(cw, bcell_row, bcell_col)
    end
    # restore default level
    # Logging.LogLevel(Info)
end
function compute_options_flexible(s::Slot, increment::Int)
    if s.flexible_start || s.flexible_end
        p = s.pattern
        if s.flexible_start p = ".*"*p end
        if s.flexible_end p = p*".*" end
        p='^'*p*'$'
        len = s.length+increment
        out = fitting_words(Regex(lowercase(p)),len,len)
        n_options = length(out[len])
        flexibility = s.flexible_start ? "start" * (s.flexible_end ? "/end" : "") : "end"
        println("- flexible $flexibility, increment: $increment => length: $(len) => #options: $n_options")
        println("\t ", out[len][1:min(n_options,10)])
        return n_options, out
    else
        @warn "Slot is not flexible."
        return 0, nothing
    end
end

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

function fill!(cw::CrosswordPuzzle; seed=rand(Int), iteration=0, verbose=false)
    # print("Iteration: $iteration\r")
    # if iteration%4 == 0 display(cw) end
    if verbose print("Completeness [%]: $(round(100*sum(cw.grid .!= EMPTY_CELL) / prod(size(cw)),digits=2))\r") end
    if iteration==0
        Random.seed!(seed)
        # rng = MersenneTwister(seed)
        # @info "Starting fill! with seed $seed"
    end
    if iteration > 600
        # println("Exiting for max iterations exceeded")
        @warn "Maximum iterations reached, aborting..."
        return false
    end
    # Base case: crossword is complete
    if is_full(cw)
        # println("Exiting for full crossword")
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
            # maybe add something here; user can know a "ner" word (not in the dictionary) to place
        end
        if n_options < min_n_options
            most_constrained_slot_idx = i
            min_n_options = n_options
            min_candidates = shuffle(candidates[s.length])
            # min_candidates = candidates[s.length]
        end
    end

    slot = slots[most_constrained_slot_idx]

    # Try all candidate words
    for word in min_candidates[1:min(length(min_candidates), 30)]
    # for word in min_candidates
        if place_word!(cw, word, slot.row, slot.col, slot.direction)
            @info "trying word '$word' at slot $slot"
            if fill!(cw, iteration=iteration+1, verbose=verbose)
                return true # SUCCESS propagates upward
            end
            remove_word!(cw, word) # backtrack
        end
    end

    # All candidates failed
    return false
end


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

