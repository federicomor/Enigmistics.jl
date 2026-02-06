# Crosswords
```@contents
Pages = ["crosswords.md"]
Depth = 2:3
```
## Structures
```@docs
CrosswordWord
CrosswordBlackCell
CrosswordPuzzle
```
Here are some useful constructors:
```@docs
CrosswordPuzzle(rows::Int, cols::Int)
CrosswordPuzzle(rows::Int, cols::Int, words::Vector{CrosswordWord})
CrosswordPuzzle(words::Vector{CrosswordWord})
```

## Interface 
```@docs
show_crossword
example_crossword
enlarge!
shrink!
can_place_word
place_word!
remove_word!
place_black_cell!
remove_black_cell!
clear!
```

## Patterns
```@docs
patterned_crossword
striped_crossword
```

## IO
```@docs
save_crossword
load_crossword
```

## Automation
```@docs
Slot
find_constrained_slots
compute_options_simple
compute_options_split
compute_options_flexible
```
```@docs
Enigmistics.fill!
```
