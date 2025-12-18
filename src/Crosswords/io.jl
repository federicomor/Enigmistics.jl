function is_full(cw::CrosswordPuzzle)
	return all(cw.grid .!= EMPTY_CELL)
end

"""
    save_crossword(cw::CrosswordPuzzle, filename::String)

Save the crossword puzzle `cw` to a text file specified by `filename`.

The grid is saved using the following conventions:
- `#` represents a black cell
- `.` represents an empty cell
- letters represent filled cells
"""
function save_crossword(cw::CrosswordPuzzle, filename::String)
    nrows, ncols = size(cw.grid)
    open(filename, "w") do io
        for r in 1:nrows
            for c in 1:ncols
                cell = cw.grid[r,c]
                if cell == BLACK_CELL print(io, "#")
                elseif cell == EMPTY_CELL print(io, ".")
                else print(io, cell)
                end
            end
            println(io)
        end
    end
end
# cw = example_crossword(type="full")
# remove_word!(cw, "narrow"); cw
# remove_word!(cw, "window"); cw
# save_crossword(cw, "ex2.txt")

# cw2 = load_crossword("ex2.txt")

function extract_horizontal_words(grid)
    nrows, ncols = size(grid)
    words = CrosswordWord[]
    for r in 1:nrows
        c = 1
        while c <= ncols
            # scan until you find a letter
            if isletter(grid[r,c])
                start = c
                # extend right
                while c <= ncols && isletter(grid[r,c])
                    c += 1
                end
                length_word = c - start
                if length_word >= 2 && (start==1 || grid[r,start-1]==BLACK_CELL)
                    word = String(grid[r, start:c-1])
                    push!(words, CrosswordWord(word, r, start, :horizontal))
                end
            end
            c += 1
        end
    end
    return words
end
cw = example_crossword(type="full")
function extract_vertical_words(grid)
    nrows, ncols = size(grid)
    words = CrosswordWord[]
    for c in 1:ncols
        r = 1
        while r <= nrows
            # scan until you find a letter
            if isletter(grid[r,c])
                start = r
                # extend down
                while r <= nrows && isletter(grid[r,c])
                    r += 1
                end
                length_word = r - start
                if length_word >= 2 && (start==1 || grid[start-1,c]==BLACK_CELL)
                    word = String(grid[start:r-1, c])
                    push!(words, CrosswordWord(word, start, c, :vertical))
                end
            end
            r += 1
        end
    end
    return words
end
function deduce_words(grid)
    vcat(
        extract_horizontal_words(grid),
        extract_vertical_words(grid),
    )
end
function read_grid(filename::String)
    lines = readlines(filename)
    nrows = length(lines)
    ncols = maximum(length.(lines))
    grid = create_grid(nrows, ncols)

    # decode symbols into their official representations of the package
    for (r, line) in enumerate(lines)
        for (c, ch) in enumerate(line)
            if ch == '#' grid[r,c] = BLACK_CELL
            elseif ch == '.' grid[r,c] = EMPTY_CELL
            else grid[r,c] = ch
            end
        end
    end
    return grid
end

"""
    load_crossword(path::String)

Load a crossword puzzle from a text file specified by `path`.

The grid should be written in the file using the following conventions:
- `#` represents a black cell
- `.` represents an empty cell
- letters represent filled cells
"""
function load_crossword(path::String)
    grid = read_grid(path)
    nrows, ncols = size(grid)
    words = deduce_words(grid)
    cw = CrosswordPuzzle(nrows, ncols, words)

    # update manual black cells if they were ignored during automatic creation
    for r in 1:nrows
        for c in 1:ncols
            if grid[r,c] == BLACK_CELL && cw.grid[r,c] != BLACK_CELL
                place_black_cell!(cw, r, c)
            end
        end
    end
    return cw
end

# pwd()
# path="Crosswords/ex1.txt"
# cw = load_crossword(path)


# cw = simple_crossword()

# function to_latex(cw:CrosswordPuzzle)
#     if !is_full(cw)
#         @error "Ensure that the crossword is complete!"
#         return
#     end

# \documentclass[12pt]{article}
# \usepackage[a4paper,margin=2cm]{geometry}
# \usepackage[unboxed,large]{cwpuzzle}
# \usepackage{xcolor}

# % Casella annerita
# % |* 
# % Casella vuota
# % |{}
# % A capo
# % |.
# % Casella numerate
# % | [numero]

# \renewcommand{\PuzzleBlackBox}{\rule{.75\PuzzleUnitlength}{.85\PuzzleUnitlength}}
# \definecolor{gray}{gray}{.9}
# \PuzzleDefineColorCell{c}{gray}

# % Schema
# \begin{document}

# \begin{center}
# \setlength{\PuzzleUnitlength}{1.5cm}

# {\Large\bfseries Cruciverba}

# \vspace{1cm}

# %\PuzzleSolution
# \begin{Puzzle}{11}{10}
#   |[1][cf] c|    u|[2][cf] r|       a|*       |*        |[3][cf] o|*    |*       |*     |*     |.
#   |        r|*    |        o|*       |[4]    g|[][cf]  a|        l|    l|[][cf] i|     n|     e|.
#   |        o|*    |[][cf]  s|*       |*       |*        |        i|*    |*       |*     |*     |.
#   |[5]     c|    r|        e|[6][cf]m|[][cf]  i|[][cf] n|        o|*    |*       |*     |*     |.
#   |[][cf]  e|*    |*        |       a|*       |*        |*        |*    |*       |*     |*     |.
#   |*        |*    |*        |       s|*       |[7]     c|*        |*    |*       |*     |*     |.
#   |*        |*    |[8]     a|[][cf] s|[][cf] t|        a|*        |*    |*       |*     |*     |.
#   |*        |*    |*        |       i|*       |        i|*        |*    |*       |*     |*     |.
#   |*        |[9] n|        o|       m|[][cf] i|*        |*        |*    |*       |*     |*     |.
#   |*        |*    |*        |       o|*       |*        |*        |*    |*       |*     |*     |.
# \end{Puzzle}

# \vspace{1cm}

# \textbf{Chiave:} \_\_\ \_\_\ \_\_\ \_\_\ \_\_\ \_\_\ \_\_\ \_\_\ \_\_\ \_\_\ \_\_\ \_\_\ \_\_
# \end{center}

# \begin{flushleft}
# % Definizioni orizzontale
# \begin{PuzzleClues}{\textbf{Orizzontale}}
# \Clue{1}{cura}{Prendersi ... dell'altro}
# \Clue{4}{galline}{Si trovano all'interno della stia}
# \Clue{5}{cremino}{Delizioso dolcetto al cioccolato}
# \Clue{8}{asta}{Regge la bandiera}
# \Clue{9}{nomi}{Possono essere comuni o propri}
# \end{PuzzleClues}

# \bigskip

# % Definizione verticale
# \begin{PuzzleClues}{\textbf{Verticale}}
# \Clue{1}{croce}{Sulla mappa indica il punto dove scavare}
# \Clue{2}{rose}{Bellissimi fiori con spine}
# \Clue{3}{olive}{Si ottiene dalle olive}
# \Clue{6}{massimo}{Si oppone al minimo}
# \Clue{7}{cai}{Club Alpino Italiano}
# \end{PuzzleClues}
# \end{flushleft}

# \end{document}