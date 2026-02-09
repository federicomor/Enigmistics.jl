"""
	CrosswordWord

Structure for a word placed in the crossword.

# Fields
- `word::String`: the actual word 
- `row::Int`: starting row
- `col::Int`: starting column
- `direction::Symbol`: either `:vertical` or `:horizontal` 
"""
mutable struct CrosswordWord 
	word::String
	row::Int
	col::Int
	direction::Symbol # :vertical or :horizontal 
end 

# some useful overloads
function Base.uppercase(cw::CrosswordWord)
	return CrosswordWord(uppercase(cw.word), cw.row, cw.col, cw.direction)
end
function Base.uppercase(cw::Vector{CrosswordWord})
	return uppercase.(cw)
end


"""
	CrosswordBlackCell

Structure for a black cell placed in the crossword.

# Fields
- `count::Float64`: number of words that share that black cell (or `Inf64` if it was manually placed)
- `manual::Bool`: if the cell was manually set by user or automatically derived based on surronding words  
"""
mutable struct CrosswordBlackCell
	count::Float64 # count of words that share that black cell
	manual::Bool # was automatic based on surronding words or was manually set by user
end


"""
	CrosswordPuzzle

Structure for a crossword puzzle.

# Fields

- `grid::Matrix{Char}`: the actual crossword grid
- `words::Vector{CrosswordWord}`: vector containing all the words
- `black_cells::Dict{Tuple{Int,Int}, CrosswordBlackCell}`: dictionary storing the black cells information
"""
mutable struct CrosswordPuzzle
	grid::Matrix{Char}
	words::Vector{CrosswordWord}
	black_cells::Dict{Tuple{Int,Int}, CrosswordBlackCell}

	function CrosswordPuzzle(grid::Matrix{Char},words::Vector{CrosswordWord},black_cells::Dict{Tuple{Int,Int}, CrosswordBlackCell})
		cw = new(grid, uppercase(words), black_cells); # uses default `new` constructor
		update_crossword!(cw); # post-construction initialization
		return cw;
	end
end

# other useful constructors
"""
	CrosswordPuzzle(rows::Int, cols::Int)
	
Construct a crossword with an empty grid of the given dimensions.

# Examples
```jldoctest
julia> cw = CrosswordPuzzle(4,5)
    1  2  3  4  5 
  ┌───────────────┐
1 │ ⋅  ⋅  ⋅  ⋅  ⋅ │
2 │ ⋅  ⋅  ⋅  ⋅  ⋅ │
3 │ ⋅  ⋅  ⋅  ⋅  ⋅ │
4 │ ⋅  ⋅  ⋅  ⋅  ⋅ │
  └───────────────┘
```
"""
function CrosswordPuzzle(rows::Int, cols::Int) 
	grid = create_grid(rows,cols);
	words = CrosswordWord[];
	black_cells = Dict{Tuple{Int,Int}, CrosswordBlackCell}();
	return CrosswordPuzzle(grid,words,black_cells);
end

"""
	CrosswordPuzzle(rows::Int, cols::Int, words::Vector{CrosswordWord})
	
Construct a crossword with the given dimensions and words. Return an error if words intersections are not compatible.

# Examples
```julia-repl
julia> words = [CrosswordWord("CAT",2,2,:horizontal), CrosswordWord("BAT",1,3,:vertical),
                CrosswordWord("SIR",4,4,:horizontal)];

julia> CrosswordPuzzle(5,6,words)
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ ⋅  ⋅  B  ⋅  ⋅  ⋅ │
2 │ ■  C  A  T  ■  ⋅ │
3 │ ⋅  ⋅  T  ⋅  ⋅  ⋅ │
4 │ ⋅  ⋅  ■  S  I  R │
5 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
  └──────────────────┘

julia> words = [CrosswordWord("CAT",2,2,:horizontal), CrosswordWord("BAT",1,3,:vertical),
                CrosswordWord("SIR",4,4,:horizontal), CrosswordWord("DOG",1,2,:vertical)];

julia> CrosswordPuzzle(5,6,words)
┌ Warning: Cannot place word 'DOG' at (1, 2) vertically due to conflict at cell (2, 2); found when checking the inner cells.
┌ Error: Words intersections are not compatible.
```
"""
function CrosswordPuzzle(rows::Int, cols::Int, words::Vector{CrosswordWord}) 
	cw = CrosswordPuzzle(rows, cols)
	all_good = true
	for w in words
		# this constructor uses place_word! (which performs the checks through can_place_word)
		# to check the intersections compatibilities of the given words
		all_good &= place_word!(cw, w)
	end
	if !all_good
		@error "Words intersections are not compatible."
		return nothing
	end
	return cw
end


"""
	CrosswordPuzzle(words::Vector{CrosswordWord})
	
Construct a crossword with the given words (dimensions are inferred from words positions). Return an error if words intersections are not compatible.

# Examples
```julia-repl
julia> words = [CrosswordWord("CAT",2,2,:horizontal), CrosswordWord("BAT",1,3,:vertical),
                CrosswordWord("SIR",4,4,:horizontal)];

julia> CrosswordPuzzle(words)
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ ⋅  ⋅  B  ⋅  ⋅  ⋅ │
2 │ ■  C  A  T  ■  ⋅ │
3 │ ⋅  ⋅  T  ⋅  ⋅  ⋅ │
4 │ ⋅  ⋅  ■  S  I  R │
  └──────────────────┘

julia> words = [CrosswordWord("CAT",2,2,:horizontal), CrosswordWord("BAT",1,3,:vertical),
                CrosswordWord("SIR",4,4,:horizontal), CrosswordWord("DOG",1,2,:vertical)];

julia> CrosswordPuzzle(5,6,words)
┌ Warning: Cannot place word 'DOG' at (1, 2) vertically due to conflict at cell (2, 2); found when checking the inner cells.
┌ Error: Words intersections are not compatible.
```
"""
function CrosswordPuzzle(words::Vector{CrosswordWord}) 
	rows=0; cols=0
	for w in words
		rows = max(rows, w.direction == :vertical ? w.row + length(w.word) - 1 : w.row )
		cols = max(cols, w.direction == :horizontal ? w.col + length(w.word) - 1 : w.col)
	end
	return CrosswordPuzzle(rows, cols, words)
end


# some useful overloads
Base.size(cw::CrosswordPuzzle) = size(cw.grid)
function Base.copy(cw::CrosswordPuzzle)
	new_grid = copy(cw.grid)
	new_words = [CrosswordWord(w.word, w.row, w.col, w.direction) for w in cw.words]
	new_black_cells = Dict{Tuple{Int64, Int64}, CrosswordBlackCell}()
	for (key,cell) in cw.black_cells
		if cell.manual
			new_black_cells[key] = cell
		end
	end
	return CrosswordPuzzle(new_grid, new_words, new_black_cells)
end
Base.:(==)(cw1::CrosswordPuzzle,cw2::CrosswordPuzzle) = cw1.grid == cw2.grid 

## do not declare this function so that the @show macro still works as we expect
# function Base.show(io::IO, cw::CrosswordPuzzle)
# 	show_crossword(io, cw, words_details=false, black_cells_details=false)
# end
## the 3-argument show used by display(obj) on the REPL
function Base.show(io::IO, mime::MIME"text/plain", cw::CrosswordPuzzle)
	show_crossword(io, cw, words_details=false, black_cells_details=false)
end


"""
	show_crossword(cw::CrosswordPuzzle; words_details=true, black_cells_details=true)

Print the crossword grid, possibly along with the words details and black cells details.

# Examples
```jldoctest
julia> cw = example_crossword(type="full") # normal output
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  O  ■  A │
3 │ T  ■  S  O  U  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ W  I  N  D  O  W │
  └──────────────────┘

julia> show_crossword(cw) # extended details output
    1  2  3  4  5  6
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  O  ■  A │
3 │ T  ■  S  O  U  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ W  I  N  D  O  W │
  └──────────────────┘

Horizontal:
 - 'GOLDEN' at (1, 1)
 - 'AN' at (2, 1)
 - 'SOUR' at (3, 3)
 - 'EVER' at (4, 1)
 - 'IE' at (5, 2)
 - 'WINDOW' at (6, 1)
Vertical:
 - 'GATE' at (1, 1)
 - 'ON' at (1, 2)
 - 'VII' at (4, 2)
 - 'SEEN' at (3, 3)
 - 'DOOR' at (1, 4)
 - 'NARROW' at (1, 6)

Black cells:
 - at (5, 5) was manually placed
 - at (3, 2) was automatically derived (delimiting 3 words)
 - at (4, 5) was automatically derived (delimiting 1 words)
 - at (2, 5) was manually placed
 - at (5, 1) was automatically derived (delimiting 2 words)
 - at (2, 3) was automatically derived (delimiting 2 words)
 - at (5, 4) was automatically derived (delimiting 2 words)
```
"""
function show_crossword(io::IO, cw::CrosswordPuzzle; words_details=true, black_cells_details=true)
	# grid
	show_grid(io, cw.grid, empty_placeholder = EMPTY_PLACEHOLDER, style="single")
	println()
	# words
	if words_details
		if any([w.direction == :horizontal for w in cw.words]) 
			println(io, "\nHorizontal:")
			for w in filter(w -> w.direction == :horizontal, cw.words)
				println(io, " - '", w.word, "' at (", w.row, ", ", w.col, ")")
			end
		end
		if any([w.direction == :vertical for w in cw.words]) 
				println(io, "Vertical:")
			for w in filter(w -> w.direction == :vertical, cw.words)
				println(io, " - '", w.word, "' at (", w.row, ", ", w.col, ")")
			end
		end
	end
	# black cells
	if black_cells_details && !isempty(cw.black_cells)
		println(io, "\nBlack cells:")
		for (pos,cell) in cw.black_cells
			println(io, " - at $pos was $(cell.manual==true ? "manually placed" : "automatically derived (delimiting $(Int(cell.count)) words)")")
		end
	end
end
show_crossword(cw::CrosswordPuzzle; words_details=true, black_cells_details=true, empty_placeholder='⋅') = show_crossword(stdout, cw; words_details=words_details, black_cells_details=black_cells_details, empty_placeholder=empty_placeholder)

"""
	update_crossword!(cw::CrosswordPuzzle)

Update the crossword grid based on the current words and manually-placed black cells (other black cells are in fact placed automatically as word delimiters). It is called upon creation of an object or internally after any change to keep the grid consistent with the updated information (e.g. words/black cells placed/removed).
"""
function update_crossword!(cw::CrosswordPuzzle)
	nrows, ncols = size(cw.grid)
	new_grid = create_grid(nrows, ncols)
	new_black_cells = Dict{Tuple{Int,Int}, CrosswordBlackCell}()

	# preserve manually placed black cells
	for (key, cell) in cw.black_cells
		# @show key, cell
		if cell.manual == true
			new_black_cells[key] = cell
			new_grid[key[1],key[2]] = BLACK_CELL
		end
	end

	# inserting words
	cw.words = uppercase(cw.words)
	for w in cw.words
		lw = length(w.word)
		if w.direction == :horizontal
			for (i, ch) in enumerate(w.word)
				new_grid[w.row, w.col + i - 1] = ch
			end
			# updating black cells
			# if a black cell already exists, we update its count based on this logic:
			# user placement => count = Infinity, automatic/derived placement: count += 1
			# otherwise we create a new black cell, initialized with count = 1 and manual = false
			if w.col-1>=1
				idx = (w.row,w.col-1) 
				new_grid[idx[1],idx[2]] = BLACK_CELL
				cell = get!(new_black_cells, idx, CrosswordBlackCell(0, false))
				cell.count += cell.manual ? Inf : 1 
			end
			if w.col+lw<=ncols 
				idx = (w.row,w.col+lw) 
				new_grid[idx[1],idx[2]] = BLACK_CELL
				cell = get!(new_black_cells, idx, CrosswordBlackCell(0, false))
				cell.count += cell.manual ? Inf : 1 
			end
		elseif w.direction == :vertical
			for (i, ch) in enumerate(w.word)
				new_grid[w.row + i - 1, w.col] = ch
			end
			# updating black cells
			if w.row-1>=1
				idx = (w.row-1,w.col) 
				new_grid[idx[1],idx[2]] = BLACK_CELL
				cell = get!(new_black_cells, idx, CrosswordBlackCell(0, false))
				cell.count += cell.manual ? Inf : 1             
			end
			if w.row+lw<=nrows 
				idx = (w.row+lw,w.col) 
				new_grid[idx[1],idx[2]] = BLACK_CELL
				cell = get!(new_black_cells, idx, CrosswordBlackCell(0, false))
				cell.count += cell.manual ? Inf : 1             
			end
		end
	end
	setfield!(cw, :grid, new_grid)
	setfield!(cw, :black_cells, new_black_cells)
end

"""
	example_crossword(; type="full") 

Return an example crossword, useful e.g during testing. Available values for now are
- "full": a complete crossword with all words
- "partial": an incomplete crossword with some words missing

# Examples
```jldoctest
julia> cw = example_crossword(type="full")
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  O  ■  A │
3 │ T  ■  S  O  U  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ W  I  N  D  O  W │
  └──────────────────┘

julia> example_crossword(type="partial")
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ ⋅  I  ⋅  ⋅  ⋅  W │
  └──────────────────┘
```
"""
function example_crossword(;type="full")
	if type=="full"
		words = [
			CrosswordWord("GOLDEN", 1, 1, :horizontal) 
			CrosswordWord("AN", 2, 1, :horizontal) 
			CrosswordWord("SOUR", 3, 3, :horizontal) 
			CrosswordWord("EVER", 4, 1, :horizontal) 
			CrosswordWord("IE", 5, 2, :horizontal) 
			CrosswordWord("WINDOW", 6, 1, :horizontal) 
			CrosswordWord("GATE", 1, 1, :vertical) 
			CrosswordWord("ON", 1, 2, :vertical) 
			CrosswordWord("VII", 4, 2, :vertical) 
			CrosswordWord("SEEN", 3, 3, :vertical) 
			CrosswordWord("DOOR", 1, 4, :vertical) 
			CrosswordWord("NARROW", 1, 6, :vertical) 
		]
		cw = CrosswordPuzzle(create_grid(6, 6), words, Dict{Tuple{Int,Int}, CrosswordBlackCell}())
		place_black_cell!(cw,2,5); place_black_cell!(cw,5,5)
		return cw
	elseif type=="partial"
		words = [
			CrosswordWord("GOLDEN", 1, 1, :horizontal) 
			CrosswordWord("AN", 2, 1, :horizontal) 
			# CrosswordWord("SOUR", 3, 3, :horizontal) 
			CrosswordWord("EVER", 4, 1, :horizontal) 
			CrosswordWord("IE", 5, 2, :horizontal) 
			# CrosswordWord("WINDOW", 6, 1, :horizontal) 
			CrosswordWord("GATE", 1, 1, :vertical) 
			CrosswordWord("ON", 1, 2, :vertical) 
			CrosswordWord("VII", 4, 2, :vertical) 
			# CrosswordWord("SEEN", 3, 3, :vertical) 
			# CrosswordWord("DOOR", 1, 4, :vertical) 
			CrosswordWord("NARROW", 1, 6, :vertical) 
		]
		cw = CrosswordPuzzle(create_grid(6, 6), words, Dict{Tuple{Int,Int}, CrosswordBlackCell}())
		place_black_cell!(cw,2,5); place_black_cell!(cw,5,5)
		return cw
	else
		@warn "Type '$type' not supported"
	end
	return nothing
end

function shift_contents!(cw::CrosswordPuzzle, (Δrow, Δcol))
	if Δrow!=0 && Δcol!=0
		@error "Shift by one direction per time."
		return false
	end
	for cword in cw.words
		if cword.row + Δrow <= 0 || cword.col + Δcol <= 0
			@error "Cannot shift words outside buondaries."
			return false
		else
			cword.row += Δrow
			cword.col += Δcol
		end
	end
	bc_new = Dict{Tuple{Int64, Int64}, CrosswordBlackCell}()
	for (key,cell) in cw.black_cells
		if cell.manual
			new_key = key .+ (Δrow,Δcol) 
			if all(new_key .>= 1)
				bc_new[new_key] = cell
			else
				@info "After this shift some black cells will collapse into borders."
			end
		end
	end
	setfield!(cw, :black_cells, bc_new)
	return true
end

"""
	enlarge!(cw::CrosswordPuzzle, how::Symbol, times=1)

Enlarge the crossword grid in the direction given by `how` (accepted values are :N, :S, :E, :O) by appropriately inserting `times` empty rows/columns.

# Examples
```jldoctest
julia> cw = example_crossword()
    1  2  3  4  5  6
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  O  ■  A │
3 │ T  ■  S  O  U  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ W  I  N  D  O  W │
  └──────────────────┘

julia> enlarge!(cw, :O); cw
    1  2  3  4  5  6  7 
  ┌─────────────────────┐
1 │ ■  G  O  L  D  E  N │
2 │ ■  A  N  ■  O  ■  A │
3 │ ⋅  T  ■  S  O  U  R │
4 │ ■  E  V  E  R  ■  R │
5 │ ⋅  ■  I  E  ■  ■  O │
6 │ ■  W  I  N  D  O  W │
  └─────────────────────┘

julia> enlarge!(cw, :N, 2); cw
    1  2  3  4  5  6  7 
  ┌─────────────────────┐
1 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
2 │ ⋅  ■  ■  ⋅  ■  ⋅  ■ │
3 │ ■  G  O  L  D  E  N │
4 │ ■  A  N  ■  O  ■  A │
5 │ ⋅  T  ■  S  O  U  R │
6 │ ■  E  V  E  R  ■  R │
7 │ ⋅  ■  I  E  ■  ■  O │
8 │ ■  W  I  N  D  O  W │
  └─────────────────────┘
```
"""
function enlarge!(cw::CrosswordPuzzle, how::Symbol, times::Int=1)
	if !(how in (:N, :S, :E, :O))
		@warn "Direction not recognised (available direction are :N, :S, :E, :O). No changes on the original grid."
		return false
	end
	# enlarge the grid
	new_grid = enlarge(cw.grid, how, times)
	setfield!(cw, :grid, new_grid)
	
	# if directions are :E or :S => nothing more to do
	# otherwise we need to shift words and black cells
	if how == :N
		shift_contents!(cw, (times,0))
	elseif how == :O
		shift_contents!(cw, (0,times))
	end
	# but alwyas we have to update the crossword, as new black cells could form
	update_crossword!(cw)
	return true
end

"""
	shrink!(cw::CrosswordPuzzle)
	
Reduce the crossword size to its minimal representation by removing useless rows/columns.

# Examples
```julia-repl
julia> cw
    1  2  3  4  5  6  7  8  9
  ┌───────────────────────────┐
1 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
2 │ ⋅  ■  ■  ⋅  ■  ⋅  ■  ⋅  ⋅ │
3 │ ■  G  O  L  D  E  N  ■  ⋅ │
4 │ ■  A  N  ■  O  ■  A  ⋅  ⋅ │
5 │ ⋅  T  ■  S  O  U  R  ■  ⋅ │
6 │ ■  E  V  E  R  ■  R  ⋅  ⋅ │
7 │ ⋅  ■  I  E  ■  ■  O  ⋅  ⋅ │
8 │ ■  W  I  N  D  O  W  ■  ⋅ │
9 │ ⋅  ⋅  ■  ■  ⋅  ⋅  ■  ⋅  ⋅ │
  └───────────────────────────┘

julia> shrink!(cw); cw
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  O  ■  A │
3 │ T  ■  S  O  U  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ W  I  N  D  O  W │
  └──────────────────┘
```
"""
function shrink!(cw::CrosswordPuzzle)
    old_nrows, old_ncols = size(cw.grid)
    new_nrows, new_ncols = size(cw.grid)
    top, bottom = 1, old_nrows
    left, right = 1, old_ncols

    # top boundary
    while top <= old_nrows && all(cw.grid[top, :] .== EMPTY_CELL .|| cw.grid[top, :] .== BLACK_CELL)
		shift_contents!(cw, (-1,0))
		new_nrows -= 1
        top += 1
    end
    # bottom boundary
    while bottom >= 1 && all(cw.grid[bottom, :] .== EMPTY_CELL .|| cw.grid[bottom, :] .== BLACK_CELL)
		new_nrows -= 1
        bottom -= 1
    end
    # left boundary
    while left <= old_ncols && all(cw.grid[:, left] .== EMPTY_CELL .|| cw.grid[:, left] .== BLACK_CELL)
		shift_contents!(cw, (0,-1))
		new_ncols -= 1
        left += 1
    end
    # right boundary
    while right >= 1 && all(cw.grid[:, right] .== EMPTY_CELL .|| cw.grid[:, right] .== BLACK_CELL)
		new_ncols -= 1
        right -= 1
    end

    # If the grid is entirely empty, return a minimal grid
    if top > bottom || left > right
        cw = CrosswordPuzzle(1, 1)
		return true
    end
	# @show new_nrows, new_ncols
	new_grid = create_grid(new_nrows, new_ncols)
	setfield!(cw, :grid, new_grid)
	update_crossword!(cw)
	return true
end




"""
	can_place_word(cw::CrosswordPuzzle, word::String, row, col, direction::Symbol)
	can_place_word(cw::CrosswordPuzzle, cwword::CrosswordWord)

Check if a word can be placed in the crossword puzzle `cw` at the given position and direction.
	
Return true if the word can be placed, false otherwise.

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

julia> can_place_word(cw, "GEEKS", 3, 3, :vertical)
┌ Warning: Word 'GEEKS' does not fit in the grid vertically at (3, 3).
false

julia> can_place_word(cw, "PEAR", 1, 4, :vertical)
┌ Warning: Cannot place word 'PEAR' at (1, 4) vertically due to conflict at cell (1, 4); found when checking the inner cells.
false

julia> can_place_word(cw, "DEAR", 1, 4, :vertical)
true
```
"""
function can_place_word(cw::CrosswordPuzzle, word::String, row::Int, col::Int, direction::Symbol)
	word = uppercase(word)
	if length(word) < 2
		@warn "Cannot insert words with less than 2 letters in a crossword."
		return false
	end
	if word in [w.word for w in cw.words]
		@warn "Word '$word' is already present in the crossword; you cannot have duplicate words in a crossword."
		return false
	end
	if !all(isletter.(c for c in word))
		@error "The provided word $word contains other characters than letters"
		return false
	end
	lw = length(word)
	nrows, ncols = size(cw.grid)
	if direction == :horizontal
		if col+lw-1 > ncols
			@warn "Word '$word' does not fit in the grid horizontally at ($row, $col)."
			return false
		end 
		# check actual contents
		for (i, ch) in enumerate(word)
			if !(cw.grid[row, col + i - 1] == EMPTY_CELL || cw.grid[row, col + i - 1] == ch)
				@warn "Cannot place word '$word' at ($row, $col) horizontally due to conflict at cell ($row, $(col + i - 1)); found when checking the inner cells."
				return false
			end
		end
		# check borders
		# before the start of the word
		if col-1>=1 && !(cw.grid[row, col-1] == EMPTY_CELL || cw.grid[row, col-1] == BLACK_CELL)
			@warn "Cannot place word '$word' at ($row, $col) horizontally due to conflict at cell ($row, $(col-1)); found when checking the border cells."
			return false
		end
		# after the end of the word
		if col+lw<=ncols && !(cw.grid[row, col+lw] == EMPTY_CELL || cw.grid[row, col+lw] == BLACK_CELL)
			@warn "Cannot place word '$word' at ($row, $col) horizontally due to conflict at cell ($row, $(col+lw)); found when checking the border cells."
			return false
		end
	elseif direction == :vertical
		if row+lw-1 > nrows
			@warn "Word '$word' does not fit in the grid vertically at ($row, $col)."
			return false
		end 
		# check actual contents
		for (i, ch) in enumerate(word)
			if !(cw.grid[row + i - 1, col] == EMPTY_CELL || cw.grid[row + i - 1, col] == ch)
				@warn "Cannot place word '$word' at ($row, $col) vertically due to conflict at cell ($(row + i - 1), $col); found when checking the inner cells."
				# @show cw.grid[row + i - 1, col], i, ch
				return false
			end
		end
		# check borders
		# before the start of the word
		if row-1>=1 && !(cw.grid[row-1,col] == EMPTY_CELL || cw.grid[row-1,col] == BLACK_CELL)
			@warn "Cannot place word '$word' at ($row, $col) vertically due to conflict at cell ($(row-1), $col); found when checking the border cells."
			return false
		end
		# after the end of the word
		if row+lw<=nrows && !(cw.grid[row+lw, col] == EMPTY_CELL || cw.grid[row+lw, col] == BLACK_CELL)
			@warn "Cannot place word '$word' at ($row, $col) vertically due to conflict at cell ($(row+lw), $col); found when checking the border cells."
			return false
		end
	else
		@error "Wrong direction provided; use :horizontal or :vertical."
		return false
	end
	return true
end
can_place_word(cw::CrosswordPuzzle, cword::CrosswordWord) = can_place_word(cw, cword.word, cword.row, cword.col, cword.direction)

"""
	place_word!(cw::CrosswordPuzzle, word::String, row, col, direction::Symbol)
	place_word!(cw::CrosswordPuzzle, cword::CrosswordWord)

Place a word in the crossword puzzle `cw` at the given position and direction, also checking if it can actually be placed.

Return true if the word was successfully placed, false otherwise.

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

julia> place_word!(cw, "cat", 6, 1, :horizontal)
┌ Warning: Cannot place word 'CAT' at (6, 1) horizontally due to conflict at cell (6, 2); found when checking the inner cells.
false

julia> place_word!(cw, "pillow", 6, 1, :horizontal)
true

julia> cw
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ P  I  L  L  O  W │
  └──────────────────┘
```
"""
function place_word!(cw::CrosswordPuzzle, word::String, row::Int, col::Int, direction::Symbol)
	word = uppercase(word)
	if can_place_word(cw, word, row, col, direction)
		push!(cw.words, CrosswordWord(word, row, col, direction))
		update_crossword!(cw)
		return true
	else 
		return false
	end
end
place_word!(cw::CrosswordPuzzle, cword::CrosswordWord) = place_word!(cw::CrosswordPuzzle, cword.word, cword.row, cword.col, cword.direction)

"""
	remove_word!(cw::CrosswordPuzzle, word::String)
	remove_word!(cw::CrosswordPuzzle, cword::CrosswordWord)

Remove a word from the crossword puzzle `cw`.
 
Return true if the word was found and removed, false otherwise.

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

julia> remove_word!(cw, "cat")
┌ Warning: Word 'CAT' not found in the crossword. No changes on the original grid.
false

julia> remove_word!(cw, "narrow")
true

julia> cw
    1  2  3  4  5  6
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  ⋅ │
3 │ T  ■  ⋅  ⋅  ⋅  ⋅ │
4 │ E  V  E  R  ■  ⋅ │
5 │ ■  I  E  ■  ■  ⋅ │
6 │ ⋅  I  ⋅  ⋅  ⋅  ⋅ │
  └──────────────────┘
```
"""
function remove_word!(cw::CrosswordPuzzle, word::String)
	word = uppercase(word)
	if !(word in [w.word for w in cw.words])
		@warn "Word '$word' not found in the crossword. No changes on the original grid."
		return false
	end
	# @show cw.words
	deleteat!(cw.words,findfirst(w->w.word==word,cw.words))
	# @show cw.words
	update_crossword!(cw)
	return true
end
remove_word!(cw::CrosswordPuzzle, cword::CrosswordWord) =  remove_word!(cw,cword.word)


"""
	place_black_cell!(cw::CrosswordPuzzle, row::Int, col::Int)

Place a black cell in the crossword puzzle `cw` at the given position. 

Return true if the black cell was successfully placed, false otherwise.

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

julia> place_black_cell!(cw, 6, 2)
┌ Warning: Cannot place black cell at position (6, 2) since cell is not empty. No changes on the original grid.
false

julia> place_black_cell!(cw, 6, 4)
true

julia> cw
    1  2  3  4  5  6
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ ⋅  I  ⋅  ■  ⋅  W │
  └──────────────────┘
```
"""
function place_black_cell!(cw::CrosswordPuzzle, row::Int, col::Int)
	idx = (row, col)
	if haskey(cw.black_cells, idx)
		@assert cw.grid[row, col] == BLACK_CELL
		@warn "Black cell already present at position $idx. No changes on the original grid."
		return false
	end
	if cw.grid[row, col] != EMPTY_CELL 
		@warn "Cannot place black cell at position $idx since cell is not empty. No changes on the original grid."
		return false
	end
	cw.black_cells[idx] = CrosswordBlackCell(Inf64, true) # we manually placed it
	update_crossword!(cw)
	return true
end


"""
	remove_black_cell!(cw::CrosswordPuzzle, row::Int, col::Int)

Remove a black cell from the crossword puzzle `cw` at the given position.

Return true if the black cell was successfully removed, false otherwise.

# Examples
```julia-repl
julia> cw = example_crossword(type="partial"); show_crossword(cw, words_details=false)
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ ⋅  I  ⋅  ⋅  ⋅  W │
  └──────────────────┘

Black cells:
 - at (5, 5) was manually placed
 - at (4, 5) was automatically derived (delimiting 1 words)
 - at (3, 2) was automatically derived (delimiting 2 words)
 - at (2, 5) was manually placed
 - at (5, 1) was automatically derived (delimiting 2 words)
 - at (2, 3) was automatically derived (delimiting 1 words)
 - at (5, 4) was automatically derived (delimiting 1 words)

julia> remove_black_cell!(cw, 3, 2)
┌ Warning: Cannot remove automatically placed black cell at position (3, 2) since it's needed as a word delimiter. No changes on the original grid.
false

julia> remove_black_cell!(cw, 5, 5)
true

julia> cw
    1  2  3  4  5  6
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  ⋅  ■  A │
3 │ T  ■  ⋅  ⋅  ⋅  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ⋅  O │
6 │ ⋅  I  ⋅  ⋅  ⋅  W │
  └──────────────────┘
```
"""
function remove_black_cell!(cw::CrosswordPuzzle, row::Int, col::Int)
	idx = (row, col)
	if !haskey(cw.black_cells, idx)
		@warn "Black cell not present at position $idx. No changes on the original grid."
		return false
	else
		if cw.black_cells[idx].manual == true
			delete!(cw.black_cells, idx)
			update_crossword!(cw)
			return true
		else
			@warn "Cannot remove automatically placed black cell at position $idx since it's needed as a word delimiter. No changes on the original grid."
			return false
		end
	end
end


# cw= example_crossword(type="full")

# enlarge!(cw,:O);cw
# enlarge!(cw,:E);cw
# enlarge!(cw,:S);cw
# enlarge!(cw,:N);cw
# shrink!(cw);cw

# cw
# remove_word!(cw,"window")
# remove_word!(cw,"or")
# cw


# enlarge!(cw, :E, 2)
# cw
# place_word!(cw, "window", 6, 1, :horizontal)
# place_word!(cw, "dog", 2, 3, :horizontal)
# place_word!(cw, "dog", 2, 4, :horizontal)
# cw
# can_place_word(cw, "dri", 2, 4, :vertical)
# place_word!(cw, "dri", 2, 4, :vertical)
# cw
# enlarge!(cw, :S, 2)
# cw
# place_word!(cw, "seb", 1, 1, :horizontal)
# cw
# remove_word!(cw, "seb")
# place_word!(cw, "pratter", 2, 1, :horizontal)

# cw
# place_black_cell!(cw, 5, 1)
# cw
# remove_black_cell!(cw, 5, 1)
# cw
# place_black_cell!(cw,5,5); cw
# remove_black_cell!(cw,5,5); cw


function is_connected(cw::CrosswordPuzzle)
    grid = cw.grid
    nrows, ncols = size(grid)

    # find any starting white cell
    start = nothing
    for i in 1:nrows, j in 1:ncols
        if grid[i, j] != BLACK_CELL
            start = (i, j)
            break
        end
    end
    # case of no white cells at all (degenerate but connected)
    start === nothing && return true

    visited = falses(nrows, ncols)
    stack = [start]
    visited[start...] = true
	
    # depth first search
    while !isempty(stack)
        i, j = pop!(stack)
        for (di, dj) in ((1,0), (-1,0), (0,1), (0,-1))
            ni, nj = i + di, j + dj
            if 1 <= ni <= nrows && 1 <= nj <= ncols
                if grid[ni, nj] != BLACK_CELL && !visited[ni, nj]
                    visited[ni, nj] = true
                    push!(stack, (ni, nj))
                end
            end
        end
    end

    # check that every white cell was visited
    for i in 1:nrows, j in 1:ncols
        if grid[i, j] != BLACK_CELL && !visited[i, j]
            return false
        end
    end
    return true
end

"""
```
random_pattern(nrows, ncols; 
	max_density=0.18, symmetry=true, double_symmetry=true, 
	seed=rand(Int))
```

Generate a crossword puzzle with black cells placed according to a random pattern which can be totally random, symmetric, or doubly symmetric (i.e. specular). 

# Arguments
- `nrows::Int`, `ncols::Int`: grid dimensions
- `max_density::Float=0.18`: maximum density of black cells
- `symmetry::Bool=true`: whether to enforce symmetry
- `double_symmetry::Bool=false`: whether to enforce double symmetry (i.e. specularity)
- `seed::Int=rand(Int)`: random seed for reproducibility

# Examples
```julia-repl
julia> random_pattern(12, 20, symmetry=false, seed=1)
     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
   ┌────────────────────────────────────────────────────────────┐
 1 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ■  ⋅  ⋅  ■ │
 2 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
 3 │ ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅ │
 4 │ ■  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ■  ⋅ │
 5 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ■  ⋅  ⋅ │
 6 │ ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 7 │ ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ■  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅ │
 8 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ■  ⋅  ⋅  ⋅  ⋅ │
 9 │ ⋅  ■  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
10 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ■  ⋅  ■  ⋅  ⋅  ■  ⋅ │
11 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ■  ⋅  ■  ⋅  ⋅  ■ │
12 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
   └────────────────────────────────────────────────────────────┘

julia> random_pattern(12, 20, symmetry=true, seed=1)
     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
   ┌────────────────────────────────────────────────────────────┐
 1 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■ │
 2 │ ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
 3 │ ■  ⋅  ⋅  ⋅  ■  ⋅  ■  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
 4 │ ■  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
 5 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ■  ⋅  ⋅ │
 6 │ ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ■  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 7 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ■  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅ │
 8 │ ⋅  ⋅  ■  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
 9 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ■ │
10 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■  ⋅  ■  ⋅  ■  ⋅  ⋅  ⋅  ■ │
11 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅ │
12 │ ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
   └────────────────────────────────────────────────────────────┘

julia> random_pattern(12, 20, symmetry=true, double_symmetry=true, seed=1)
     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 
   ┌────────────────────────────────────────────────────────────┐
 1 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
 2 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
 3 │ ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■ │
 4 │ ■  ⋅  ■  ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■  ■  ⋅  ■ │
 5 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
 6 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ■  ■  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 7 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ■  ■  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 8 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
 9 │ ■  ⋅  ■  ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■  ■  ⋅  ■ │
10 │ ■  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ■ │
11 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
12 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
   └────────────────────────────────────────────────────────────┘
```
"""
function random_pattern(nrows::Int, ncols::Int; max_density::Real = 0.18, symmetry::Bool = true, 
							double_symmetry::Bool = false, seed::Int=rand(Int))
	@info "Using seed" seed
	Random.seed!(seed)
	cw = CrosswordPuzzle(nrows, ncols)

	if !(0<=max_density<=1) @error "Max density should be between 0 and 1."; return cw end 
	if (double_symmetry && !symmetry) @error "Cannot have double simmetry without single simmetry"; return cw end 

	density = 0
	black_cells = 0
	iterations = 0
	max_it = 500

	while density < max_density && iterations < max_it
		iterations += 1
		i = rand(1:nrows)
		j = rand(1:ncols)

		black_cells += place_black_cell!(cw,i,j)
		if !is_connected(cw)
			black_cells -= remove_black_cell!(cw,i,j)
			continue
		end

		if symmetry
			black_cells += place_black_cell!(cw,nrows-i+1,ncols-j+1)
			if !is_connected(cw)
				black_cells -= remove_black_cell!(cw,i,j)
				black_cells -= remove_black_cell!(cw,nrows-i+1,ncols-j+1)
				continue
			end
			if double_symmetry
				black_cells += place_black_cell!(cw,i,ncols-j+1)
				black_cells += place_black_cell!(cw,nrows-i+1,j)
				if !is_connected(cw)
					black_cells -= remove_black_cell!(cw,i,j)
					black_cells -= remove_black_cell!(cw,i,ncols-j+1)
					black_cells -= remove_black_cell!(cw,nrows-i+1,j)
					black_cells -= remove_black_cell!(cw,nrows-i+1,ncols-j+1)
					continue
				end
			end
		end
		density = black_cells / (nrows*ncols)
		# display(cw)
	end
	# @show black_cells, density
	return cw
end

# using Logging
# with_logger(NullLogger()) do
# random_pattern(12, 20, symmetry=false, seed=123)
# random_pattern(12, 20, symmetry=true, seed=456)
# random_pattern(12, 20, symmetry=true, double_symmetry=true, seed=789)
# end


"""
```
striped_pattern(nrows, ncols; 
	max_density = 0.18, 
	min_stripe_dist = 4, keep_stripe_prob = 0.9,
	symmetry = true, double_symmetry = false, 
	seed=rand(Int))
```

Generate a crossword puzzle with black cells placed according to a striped pattern which can be random, symmetric, or doubly symmetric (i.e. specular). 

# Arguments
- `nrows::Int`, `ncols::Int`: grid dimensions
- `max_density::Float=0.18`: maximum density of black cells
- `min_stripe_dist::Int=4`: minimum distance allowed between stripes
- `keep_stripe_prob::Float=0.8`: probability of continuing a stripe
- `symmetry::Bool=true`: whether to enforce symmetry
- `double_symmetry::Bool=false`: whether to enforce double symmetry (i.e. specularity)
- `seed::Int=rand(Int)`: random seed for reproducibility

# Examples
```julia-repl
julia> striped_pattern(12, 20, symmetry=false, seed=1)
     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 
   ┌────────────────────────────────────────────────────────────┐
 1 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 2 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅ │
 3 │ ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
 4 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅ │
 5 │ ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅ │
 6 │ ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
 7 │ ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
 8 │ ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
 9 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■ │
10 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
11 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅ │
12 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅ │
   └────────────────────────────────────────────────────────────┘

julia> striped_pattern(12, 20, symmetry=true, seed=1)
     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 
   ┌────────────────────────────────────────────────────────────┐
 1 │ ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 2 │ ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅ │
 3 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
 4 │ ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅ │
 5 │ ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅ │
 6 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
 7 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 8 │ ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■ │
 9 │ ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅ │
10 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
11 │ ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅ │
12 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅ │
   └────────────────────────────────────────────────────────────┘

julia>  striped_pattern(12, 20, symmetry=true, double_symmetry=true, seed=1)
     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 
   ┌────────────────────────────────────────────────────────────┐
 1 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 2 │ ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅ │
 3 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
 4 │ ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅ │
 5 │ ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅ │
 6 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 7 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
 8 │ ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅ │
 9 │ ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅ │
10 │ ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅ │
11 │ ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅ │
12 │ ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ⋅  ⋅  ■  ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
   └────────────────────────────────────────────────────────────┘
```
"""
function striped_pattern(nrows::Int, ncols::Int; max_density::Real = 0.18, 
						   min_stripe_dist::Int = 4, keep_stripe_prob::Real = 0.8,
						   symmetry::Bool = true, double_symmetry::Bool = false, seed::Int=rand(Int))
	@info "Using seed" seed
	Random.seed!(seed)
	cw = CrosswordPuzzle(nrows, ncols)

	if !(0<=max_density<=1) @error "Max density should be between 0 and 1."; return cw end 
	if (double_symmetry && !symmetry) @error "Cannot have double simmetry without single simmetry"; return cw end 

	density = 0
	black_cells = 0
	iterations = 0
	max_it = 500

	i = 0; j = 0
	prev_i = 0; prev_j = 0
	dir = rand((1,2)) # directions_types = ['/', '\\'] 
	restart_search = false
	di, dj = dir==1 ? (1, -1) : (1, 1)

	while density < max_density && iterations < max_it
		prev_i = i; prev_j = j
		i = rand(1:nrows); j = rand(1:ncols)
		iterations +=1

		if iterations > 0 
			if keep_stripe_prob >= rand() && restart_search==false
				# we go on with the stripe
				if (prev_i==1 && di==-1) || (prev_i==nrows && di==+1) di*= -1 end
				if (prev_j==1 && dj==-1) || (prev_j==ncols && dj==+1) dj*= -1 end
				i = mod1(prev_i + di,nrows)
				j = mod1(prev_j + dj,ncols)
			else
				# reset stripe parameters
				restart_search = false
				dir = 3-dir
				di, dj = dir==1 ? (1, -1) : (1, 1)
				continue
			end
			
			enough_space = all(cw.grid[max(1,i-min_stripe_dist):min(i+min_stripe_dist,nrows),j] .!= BLACK_CELL) &&
						   all(cw.grid[i,max(1,j-min_stripe_dist):min(j+min_stripe_dist,ncols)] .!= BLACK_CELL)
			if !enough_space
				# reset stripe parameters
				restart_search = false
				dir = 3-dir
				di, dj = dir==1 ? (1, -1) : (1, 1)
				continue
			end
		end

		black_cells += place_black_cell!(cw,i,j)
		if !is_connected(cw)
			black_cells -= remove_black_cell!(cw,i,j)
			restart_search = true
			continue
		end

		if symmetry
			black_cells += place_black_cell!(cw,nrows-i+1,ncols-j+1)
			if !is_connected(cw)
				black_cells -= remove_black_cell!(cw,i,j)
				black_cells -= remove_black_cell!(cw,nrows-i+1,ncols-j+1)
				restart_search = true
				continue
			end
			if double_symmetry
				black_cells += place_black_cell!(cw,i,ncols-j+1)
				black_cells += place_black_cell!(cw,nrows-i+1,j)
				if !is_connected(cw)
					black_cells -= remove_black_cell!(cw,i,j)
					black_cells -= remove_black_cell!(cw,i,ncols-j+1)
					black_cells -= remove_black_cell!(cw,nrows-i+1,j)
					black_cells -= remove_black_cell!(cw,nrows-i+1,ncols-j+1)
					restart_search = true
					continue
				end
			end
		end
		density = black_cells / (nrows*ncols)
		# display(cw)
	end
	return cw
end

# striped_pattern(12,20, symmetry=false, seed=123)
# striped_pattern(12,20, symmetry=true, seed=456)
# striped_pattern(12,20, symmetry=true, double_symmetry=true, seed=789)
	
# function random_pattern_gen(nrows::Int, ncols::Int; max_density::Real = 0.18, 
# 							stripes_prob::Real=0.7, change_dir_prob::Real=0.3,
# 							symmetry::Bool = true, double_symmetry::Bool = false, seed::Int=rand(Int))
# 	@info "Using seed" seed
# 	Random.seed!(seed)
# 	cw = CrosswordPuzzle(nrows, ncols)

# 	if !(0<=max_density<=1) @error "Max density should be between 0 and 1."; return cw end 
# 	if (double_symmetry && !symmetry) @error "Cannot have double simmetry without single simmetry"; return cw end 

# 	density = 0
# 	black_cells = 0
# 	iterations = 0
# 	i = 0; j = 0
# 	dirs = [(1,1),(1,-1),( -1,1),(-1,-1)]
# 	di, dj =  0, 0
# 	prev_i = 0; prev_j = 0

# 	while density < max_density && iterations < 500
# 		prev_i = i; prev_j = j
# 		i = rand(1:nrows); j = rand(1:ncols)

# 		if stripes_prob>0
# 			if stripes_prob >= rand() && iterations > 0 
# 				if change_dir_prob>=rand()
# 					di, dj = rand(dirs)
# 				end
# 				i = mod1(prev_i + di,nrows)
# 				j = mod1(prev_j + dj,ncols)
# 			end
# 		end

# 		black_cells += place_black_cell!(cw,i,j)
# 		if !is_connected(cw)
# 			black_cells -= remove_black_cell!(cw,i,j)
# 			continue
# 		end

# 		if symmetry
# 			black_cells += place_black_cell!(cw,nrows-i+1,ncols-j+1)
# 			if !is_connected(cw)
# 				black_cells -= remove_black_cell!(cw,i,j)
# 				black_cells -= remove_black_cell!(cw,nrows-i+1,ncols-j+1)
# 				continue
# 			end
# 			if double_symmetry
# 				black_cells += place_black_cell!(cw,i,ncols-j+1)
# 				black_cells += place_black_cell!(cw,nrows-i+1,j)
# 				if !is_connected(cw)
# 					black_cells -= remove_black_cell!(cw,i,j)
# 					black_cells -= remove_black_cell!(cw,i,ncols-j+1)
# 					black_cells -= remove_black_cell!(cw,nrows-i+1,j)
# 					black_cells -= remove_black_cell!(cw,nrows-i+1,ncols-j+1)
# 					continue
# 				end
# 			end
# 		end
# 		density = black_cells / (nrows*ncols)
# 		iterations += 1
# 		# display(cw)
# 	end
# 	# @show black_cells, density
# 	if iterations >= 1000 @error "Max iterations reached (very strange?)." end
# 	return cw
# end
# random_pattern_gen(14,20, max_density=0.18, stripes_prob=0.6, change_dir_prob=0.6,
# 	# seed = 12
# )


# cw = example_crossword(type="full")
# cw.words
"""
	clear!(cw::CrosswordPuzzle; deep=true)

Clear all words, possibly preserving manually-placed black cells (with `deep=false`), from the crossword puzzle `cw`.

# Examples
```julia-repl
julia> cw = example_crossword(); show_crossword(cw, words_details=false)
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ G  O  L  D  E  N │
2 │ A  N  ■  O  ■  A │
3 │ T  ■  S  O  U  R │
4 │ E  V  E  R  ■  R │
5 │ ■  I  E  ■  ■  O │
6 │ W  I  N  D  O  W │
  └──────────────────┘

Black cells:
 - at (5, 5) was manually placed
 - at (3, 2) was automatically derived (delimiting 3 words)
 - at (4, 5) was automatically derived (delimiting 1 words)
 - at (2, 5) was manually placed
 - at (5, 1) was automatically derived (delimiting 2 words)
 - at (2, 3) was automatically derived (delimiting 2 words)
 - at (5, 4) was automatically derived (delimiting 2 words)

julia> clear!(cw, deep=false)
    1  2  3  4  5  6 
  ┌──────────────────┐
1 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
2 │ ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
3 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
4 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
5 │ ⋅  ⋅  ⋅  ⋅  ■  ⋅ │
6 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
  └──────────────────┘

julia> clear!(cw)
    1  2  3  4  5  6
  ┌──────────────────┐
1 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
2 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
3 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
4 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
5 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
6 │ ⋅  ⋅  ⋅  ⋅  ⋅  ⋅ │
  └──────────────────┘
```
"""
function clear!(cw::CrosswordPuzzle; deep=true)
	empty!(cw.words)
	if deep empty!(cw.black_cells) end
	update_crossword!(cw)
	return cw
end

# cw = example_crossword(); show_crossword(cw, words_details=false)
# clear!(cw, deep=false)
# clear!(cw)
