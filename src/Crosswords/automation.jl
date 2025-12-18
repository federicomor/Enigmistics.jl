is_black(c) = c == BLACK_CELL
is_empty(c) = c == EMPTY_CELL

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

function find_constrained_slots(cw::CrosswordPuzzle)
    vcat(
        find_horizontal_slots(cw.grid),
        find_vertical_slots(cw.grid)
    )
end

# cd("src/Crosswords")
cw = load_crossword("ex1.txt")
remove_word!(cw, "window")
remove_word!(cw, "vii"); cw
remove_word!(cw, "seen"); cw
remove_word!(cw, "narrow"); cw

find_vertical_slots(cw.grid)
find_horizontal_slots(cw.grid)
slots = find_constrained_slots(cw)


function compute_options_simple(s::Slot)
    p = s.pattern
    p = '^'*p*'$' # fixing start and end positions, actually not necessary since length is constricted
    out = fitting_words(Regex(lowercase(p)),s.length,s.length)
    n_options = length(out[s.length])
    println("- length: $(s.length) => #options: $n_options")
    println("\t ", out[s.length][1:min(n_options,10)])
    return n_options, out
end
# function compute_options_split(s::Slot)
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
        println("- (flexible $flexibility, increment=$increment) length: $(len) => #options: $n_options")
        println("\t ", out[len][1:min(n_options,10)])
        return n_options, out
    else
        @warn "Slot is not flexible."
        return 0, nothing
    end
end

# function fit_flexible_proposal(s::Slot, increment::Int, choice::String)
    
function compute_options(s::Slot)
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
    # if s.length >= 
    # println("==== WITH BLACK CELLS ====")
end

compute_options(slots[2]) # 39 101 152
compute_options(slots[3]) # 12 15 35
compute_options(slots[4]) # 240 57 687 995

for s in slots
    results = fitting_words(Regex(lowercase(s.pattern)),s.length,s.length)
    n_options = length(results[s.length])
    println("for Slot $s we have ", n_options, " options")
    if n_options <= 15
        println("\t", results[s.length])
    end
end
