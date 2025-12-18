using Random

BLACK_CELL = '■'
EMPTY_CELL = ' '

ALPHABET = collect('A':'Z')
EXT_ALPHABET = copy(ALPHABET)
push!(EXT_ALPHABET,BLACK_CELL)
push!(EXT_ALPHABET,EMPTY_CELL)

"""
    create_grid(rows::Int, cols::Int; type="blank", probability=1.0, from=ALPHABET)

Create a grid of given number of `rows` and `cols`. 

The argument `type` can either be "blank" (all empty cells) or "random" (grid randomly filled with density proportional to the given probability), while `from` indicates the set of characters to use when filling the grid randomly (default is ALPHABET, which contains only letters, otherwise there is EXT_ALPHABET which also contains black and empty cells).

# Examples
```julia-repl   
julia> create_grid(4,4,type="blank")
4×4 Matrix{Char}:
 ' '  ' '  ' '  ' '
 ' '  ' '  ' '  ' '
 ' '  ' '  ' '  ' '
 ' '  ' '  ' '  ' '

julia> create_grid(4,4,type="random")
4×4 Matrix{Char}:
 'G'  'V'  'A'  'Y'
 'X'  'U'  'N'  'B'
 'X'  'Z'  'P'  'B'
 'J'  'E'  'Z'  'U'

julia> create_grid(4,4,type="random",probability=0.7, from=EXT_ALPHABET)
4×4 Matrix{Char}:
 ' '  'H'  'D'  ' '
 ' '  ' '  'H'  ' '
 'U'  'E'  ' '  'P'
 '■'  'B'  'C'  'A'
```
"""
function create_grid(rows::Int, cols::Int; type="blank", probability=1.0, from=ALPHABET)
    grid = fill(EMPTY_CELL, (rows, cols))
    if type=="blank" 
        return grid
    elseif type=="random"
        for i in 1:rows, j in 1:cols
            if rand() <= probability 
                grid[i, j] = rand(from)
            end
        end
        return grid
    else 
        error("Unknown grid type: $type")
    end
end


function cpad(n::Int, pad::Int)
    pad = pad-ndigits(n)
    left_space = Int(floor(pad/2))
    right_space = pad-left_space
    out_string = " "^left_space * string(n) * " "^right_space
    return out_string
end
function cpad(s::Union{String,Char}, pad::Int)
    pad = pad-length(s)
    left_space = Int(floor(pad/2))
    right_space = pad-left_space
    out_string = " "^left_space * s * " "^right_space
    return out_string
end

"""
    show_grid(grid::Matrix{Char}; empty_placeholder = "⋅", style="single")

Show the grid in the console, with optional placeholder for empty cells and style of borders (either "single" or "double").    

# Examples
```julia-repl
julia> g = create_grid(10,10,type="random", from=EXT_ALPHABET);

julia> show_grid(g,style="single")
     1  2  3  4  5  6  7  8  9 10 
   ┌──────────────────────────────┐
 1 │ M  O  X  H  M  U  J  I  X  O │
 2 │ N  H  M  ⋅  Z  Y  A  E  ⋅  W │
 3 │ N  W  U  Z  P  A  P  X  M  L │
 4 │ W  ⋅  ⋅  C  G  I  H  D  X  J │
 5 │ H  B  X  S  S  T  P  E  O  P │
 6 │ ⋅  C  Y  L  K  N  H  N  Q  ⋅ │
 7 │ ■  ⋅  N  Y  H  D  R  L  P  F │
 8 │ D  A  G  D  B  L  U  W  J  C │
 9 │ D  V  V  ■  R  O  S  A  V  M │
10 │ ■  Z  N  P  U  G  J  W  O  C │
   └──────────────────────────────┘
julia> show_grid(g,style="double", empty_placeholder = "_")
     1  2  3  4  5  6  7  8  9 10
   ╔══════════════════════════════╗
 1 ║ M  O  X  H  M  U  J  I  X  O ║
 2 ║ N  H  M  _  Z  Y  A  E  _  W ║
 3 ║ N  W  U  Z  P  A  P  X  M  L ║
 4 ║ W  _  _  C  G  I  H  D  X  J ║
 5 ║ H  B  X  S  S  T  P  E  O  P ║
 6 ║ _  C  Y  L  K  N  H  N  Q  _ ║
 7 ║ ■  _  N  Y  H  D  R  L  P  F ║
 8 ║ D  A  G  D  B  L  U  W  J  C ║
 9 ║ D  V  V  ■  R  O  S  A  V  M ║
10 ║ ■  Z  N  P  U  G  J  W  O  C ║
   ╚══════════════════════════════╝
```
"""
function show_grid(io::IO, grid::Matrix{Char}; empty_placeholder = "⋅", style="single")
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
show_grid(grid::Matrix{Char}; empty_placeholder = "⋅", style="single") = show_grid(stdout,grid; empty_placeholder=empty_placeholder,style=style)


function insert_row_above(grid::Matrix{Char}, times::Int=1)
    old_nrows, old_ncols = size(grid)
    new_grid = create_grid(old_nrows+times, old_ncols, type="blank")
    for i in 1:old_nrows
        for j in 1:old_ncols
            new_grid[i+times, j] = grid[i, j]
        end
    end
    return new_grid
end
function insert_row_below(grid::Matrix{Char}, times::Int=1)
    old_nrows, old_ncols = size(grid)
    new_grid = create_grid(old_nrows+times, old_ncols, type="blank")
    for i in 1:old_nrows
        for j in 1:old_ncols
            new_grid[i, j] = grid[i, j]
        end
    end
    return new_grid
end
function insert_col_right(grid::Matrix{Char}, times::Int=1)
    old_nrows, old_ncols = size(grid)
    new_grid = create_grid(old_nrows, old_ncols+times, type="blank")
    for i in 1:old_nrows
        for j in 1:old_ncols
            new_grid[i, j] = grid[i, j]
        end
    end
    return new_grid
end
function insert_col_left(grid::Matrix{Char}, times::Int=1)
    old_nrows, old_ncols = size(grid)
    new_grid = create_grid(old_nrows, old_ncols+times, type="blank")
    for i in 1:old_nrows
        for j in 1:old_ncols
            new_grid[i, j+times] = grid[i, j]
        end
    end
    grid = new_grid
end

function enlarge(grid::Matrix{Char}, how::Symbol, times::Int=1)
    how in (:row_above, :row_below, :col_left, :col_right) && return eval(Symbol("insert_", how))(grid, times)
end
