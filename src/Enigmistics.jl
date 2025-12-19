module Enigmistics

using ProgressMeter
using Random
using Logging

include("Wordgames/constants.jl")
include("Wordgames/text_utils.jl")
include("Wordgames/pangrams.jl")
include("Wordgames/anagrams.jl")
include("Wordgames/heterograms.jl")
include("Wordgames/lipograms.jl")
include("Wordgames/palindromes.jl")
include("Wordgames/tautograms.jl")

export clean_read, clean_text, count_letters, snip
export is_pangram, scan_for_pangrams
export are_anagrams, scan_for_anagrams
export is_heterogram, scan_for_heterograms
export is_lipogram, scan_for_lipograms
export is_palindrome, scan_for_palindromes
export is_tautogram, scan_for_tautograms

include("Crosswords/grid_utils.jl")
include("Crosswords/crosswords.jl")
include("Crosswords/io.jl")

# export create_grid, show_grid, 
    # insert_row_above, insert_row_below, insert_col_right, insert_col_left, enlarge, shrink

export CrosswordWord, CrosswordBlackCell, CrosswordPuzzle, show_crossword, example_crossword
export enlarge!, shrink!, can_place_word, place_word!, remove_word!, place_black_cell!, remove_black_cell!, patterned_crossword
export save_crossword, load_crossword

end # module Enigmistics
