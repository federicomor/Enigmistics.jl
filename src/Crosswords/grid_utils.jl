using Random

BLACK_CELL = '■'
EMPTY_CELL = ' '
EMPTY_PLACEHOLDER = '⋅'
is_black(c) = c == BLACK_CELL
is_empty(c) = c == EMPTY_CELL

ALPHABET = collect('A':'Z')
EXT_ALPHABET = copy(ALPHABET)
push!(EXT_ALPHABET,BLACK_CELL)
push!(EXT_ALPHABET,EMPTY_CELL)

function create_grid(rows::Int, cols::Int)
    grid = fill(EMPTY_CELL, (rows, cols))
    return grid
end

# "center padding", helper for the show_grid function
function cpad(data, pad::Int)
    pad = pad-length(string(data))
    left_space = Int(floor(pad/2))
    right_space = pad-left_space
    out_string = " "^left_space * string(data) * " "^right_space
    return out_string
end


function show_grid(io::IO, grid::Matrix{Char}; empty_placeholder = EMPTY_PLACEHOLDER, style="single")
    nrows, ncols = size(grid)
    h_pad = max(3,ndigits(maximum(size(grid)[2]))+1)
    left_pad = ndigits(maximum(size(grid)[1]))+1 # +1 for space character

    borders = ['┌','┐','─','│','└','┘']
    if style == "double"
        borders = ['╔','╗','═','║','╚','╝']
    end

    ## FIRST ROW:
    # spaces
    print(io, " "^(left_pad+1)) # +1 for the border character
    # column indexes
    for j in 1:ncols
        print(io, cpad(j,h_pad))
    end
    println(io, "")

    ## SECOND ROW: top border
    print(io, " "^left_pad, borders[1], borders[3]^(ncols*h_pad), borders[2])
    println(io, "")
    
    ## GRID CONTENT:
    for i in 1:nrows
        # row indexes
        print(io, lpad(i, left_pad-1, " "), " ", borders[4])
        # actual content
        for j in 1:ncols
            print(io, cpad(grid[i, j] == EMPTY_CELL ? empty_placeholder : grid[i,j], h_pad))
        end
        print(io, borders[4])
        println(io, "")
    end

    ## LAST ROW: bottom border
    print(io, " "^left_pad, borders[5], borders[3]^(ncols*h_pad), borders[6])
end
show_grid(grid::Matrix{Char}; empty_placeholder = '⋅', style="single") = show_grid(stdout,grid; empty_placeholder=empty_placeholder,style=style)


function insert_direction_N(grid::Matrix{Char}, times::Int=1)
    old_nrows, old_ncols = size(grid)
    new_grid = create_grid(old_nrows+times, old_ncols)
    for i in 1:old_nrows
        for j in 1:old_ncols
            new_grid[i+times, j] = grid[i, j]
        end
    end
    return new_grid
end
function insert_direction_S(grid::Matrix{Char}, times::Int=1)
    old_nrows, old_ncols = size(grid)
    new_grid = create_grid(old_nrows+times, old_ncols)
    for i in 1:old_nrows
        for j in 1:old_ncols
            new_grid[i, j] = grid[i, j]
        end
    end
    return new_grid
end
function insert_direction_E(grid::Matrix{Char}, times::Int=1)
    old_nrows, old_ncols = size(grid)
    new_grid = create_grid(old_nrows, old_ncols+times)
    for i in 1:old_nrows
        for j in 1:old_ncols
            new_grid[i, j] = grid[i, j]
        end
    end
    return new_grid
end
function insert_direction_O(grid::Matrix{Char}, times::Int=1)
    old_nrows, old_ncols = size(grid)
    new_grid = create_grid(old_nrows, old_ncols+times)
    for i in 1:old_nrows
        for j in 1:old_ncols
            new_grid[i, j+times] = grid[i, j]
        end
    end
    grid = new_grid
end

function enlarge(grid::Matrix{Char}, how::Symbol, times::Int=1)
    how in (:N, :S, :E, :O) && return eval(Symbol("insert_direction_", how))(grid, times)
end
