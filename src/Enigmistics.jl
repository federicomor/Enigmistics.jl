module Enigmistics

using ProgressMeter
using Random
using Logging

@info "==== Wordgames section loading ===="
@info "Including Wordgames/_constants.jl";   include("Wordgames/_constants.jl")
@info "Including Wordgames/_text_utils.jl";  include("Wordgames/_text_utils.jl")
@info "Including Wordgames/pangrams.jl";    include("Wordgames/pangrams.jl")
@info "Including Wordgames/anagrams.jl";    include("Wordgames/anagrams.jl")
@info "Including Wordgames/heterograms.jl"; include("Wordgames/heterograms.jl")
@info "Including Wordgames/lipograms.jl";   include("Wordgames/lipograms.jl")
@info "Including Wordgames/palindromes.jl"; include("Wordgames/palindromes.jl")
@info "Including Wordgames/tautograms.jl";  include("Wordgames/tautograms.jl")
@info "Including Wordgames/abecedaries.jl"; include("Wordgames/abecedaries.jl")

export clean_read, clean_text, count_letters, snip
export is_pangram, scan_for_pangrams
export are_anagrams, scan_for_anagrams
export is_heterogram, scan_for_heterograms
export is_lipogram, scan_for_lipograms
export is_palindrome, scan_for_palindromes
export is_tautogram, scan_for_tautograms
export is_abecedary, scan_for_abecedaries
@info "============ finished Wordgames exports"

@info "==== Crosswords section loading ===="
@info "Including Crosswords/grid_utils.jl"; include("Crosswords/grid_utils.jl")
@info "Including Crosswords/crosswords.jl"; include("Crosswords/crosswords.jl")
@info "Including Crosswords/io.jl";         include("Crosswords/io.jl")
@info "Including Crosswords/dictionary.jl"; include("Crosswords/dictionary.jl")
@info "Including Crosswords/automation.jl"; include("Crosswords/automation.jl")

export CrosswordWord, CrosswordBlackCell, CrosswordPuzzle, show_crossword, example_crossword
export enlarge!, shrink!, can_place_word, place_word!, remove_word!, place_black_cell!, remove_black_cell!
export random_pattern, striped_pattern, clear!
export save_crossword, load_crossword
export setup_dictionary
export Slot, find_constrained_slots, compute_options_simple, compute_options_split, compute_options_flexible
@info "============ finished Crosswords exports"

end # module Enigmistics
