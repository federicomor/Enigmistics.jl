# Enigmistics
Julia suite for wordgames and crosswords. 

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://federicomor.github.io/Enigmistics.jl/
[![][docs-stable-img]][docs-stable-url]\
<img src="docs/src/assets/logo.png" alt="drawing" width="200" style="display: block; margin-left: auto; margin-right: auto;"/>

Enigmistics.jl is a Julia package for exploring and analyzing language puzzles, in particular crosswords and wordgames. More precisely, this package provides utilities for

- efficiently finding wordgames in texts; current supported ones are abecedaries, anagrams, heterograms, lipograms, palindromes, pangrams, tautograms. For each of them, two functions are provided: one to check if a given text satisfies the wordgame constraints (e.g. function `is_pangram`) and one to find all substrings from a given text which satisfy the wordgame constraints (e.g. function `scan_for_pangrams`).

- working with crosswords. You can create empty or patterned crosswords, edit them by adding or removing words and black cells, save/load crosswords to/from a file, enlarge/shrink the grid to expand an existing one and, most importantly, you can fill in the words of an empty or partially complete crossword. For now this functionality is available fully automatically, but I plan to implement a semi-automatic version where one can manually filter the to-be-inserted words. Words can be be taken from built-in dictionaries; current supported ones are english and italian. 

## Wordgames usecase

Suppose we are a fan of John Milton's Paradise Lost poem and we would like to inspect it to find some interesting wordgames. We can start by loading the book through the `clean_read` function, which loads the text removing useless newlines or spaces which could reduce the clarity of the output from the wordgames scanning functions:
```julia-repl 
julia> text = clean_read("../Enigmistics/texts/paradise_lost.txt", newline_replace="/")
"PARADISE LOST / BOOK I. / Of Mans First Disobedience, and the Fruit / Of that Forbidden Tree, whose mortal tast / Brought Death into the World, and all our woe, / With loss of EDEN, till one greater Man / Restore us, and regain the blissful Seat, / Sing Heav'nly Muse, that on the secret top / Of OREB, or of SINAI, didst inspire / That Shepherd, who first taught the chosen Seed, / In the Beginning how the Heav'ns and Earth / Rose out of CHAOS: Or if SION Hill / Delight thee more, and SILOA" ⋯ 474211 bytes ⋯ "iff as fast / To the subjected Plaine; then disappeer'd. / They looking back, all th' Eastern side beheld / Of Paradise, so late thir happie seat, / Wav'd over by that flaming Brand, the Gate / With dreadful Faces throng'd and fierie Armes: / Som natural tears they drop'd, but wip'd them soon; / The World was all before them, where to choose / Thir place of rest, and Providence thir guide: / They hand in hand with wandring steps and slow, / Through EDEN took thir solitarie way. / THE END."
``` 

We can start by looking for pangrams, i.e. sequence of words which contain all the letters of the alphabet. We can do it by calling the `scan_for_pangrams` function, which takes as input the text to be scanned and some optional parameters to filter the output (e.g. maximum length in letters, language, etc):
```julia-repl
julia> scan_for_pangrams(text, max_length_letters=80, language="en")
Scanning for pangrams... 100%|██████████████████████████████████████████████| Time: 0:00:00
1-element Vector{Any}:
 (21698:21804, "Grazed Ox, / JEHOVAH, who in one Night when he pass'd / From EGYPT marching, equal'd with one stroke / Both")
```

It seems that there is only one "interesting" (in the sense of not being too long) pangram in the whole text. Nice.\
In a similar fashion we can now look for other wordgames. For example: are there sequences of words 

- which all start with the same letter?
```julia-repl
julia> scan_for_tautograms(text, min_length_words=5, max_length_words=20)
6-element Vector{Any}:
 (20801:20830, "and ASCALON, / And ACCARON and")
 (110257:110281, "Topaz, to the Twelve that")
 (136170:136194, "to taste that Tree, / The")
 (320005:320030, "her Husbands hand her hand")
 (450274:450301, "Though to the Tyrant thereby")
 (456113:456141, "Through the twelve Tribes, to")
```

- where their initials are in alphabetical order?
```julia-repl
julia> scan_for_abecedaries(text, min_length_words=4, max_length_words=5, language="en")
Scanning for abecedaries... 100%|███████████████████████████████████████████| Time: 0:00:00
3-element Vector{Any}:
 (102463:102490, "a boundless Continent / Dark")
 (368827:368846, "raging Sea / Tost up")
 (405485:405502, "and both confess'd")
```

- where all letters are different?
```julia-repl
julia> scan_for_heterograms(text, min_length_letters=15)
Scanning for heterograms... 100%|███████████████████████████████████████████| Time: 0:00:00
8-element Vector{Any}:
 (16997:17015, "worth / Came singly")
 (106504:106524, "of LUZ, / Dreaming by")
 (113218:113235, "works, but chiefly")
 (113218:113239, "works, but chiefly Man")
 (142414:142431, "works, and chiefly")
 (229224:229240, "and briefly touch")
 (277449:277465, "lead thy ofspring")
 (369900:369917, "scourg'd with many)
```

- where letters E and T do not appear?
```julia-repl
julia> scan_for_lipograms(text, "ET"; min_length_letters=34, max_length_letters=100)
Scanning for lipograms... 100%|███████████████████████████████████████████| Time: 0:00:00        
8-element Vector{Any}:
 (65052:65094, "foul in many a scaly fould / Voluminous and")
 (143410:143454, "by morrow dawning I shall know. / So promis'd")
 (242542:242583, "Rowld inward, and a spacious Gap disclos'd")
 (442481:442523, "by his command / Shall build a wondrous Ark")
 (442481:442527, "by his command / Shall build a wondrous Ark, as")
 (442484:442527, "his command / Shall build a wondrous Ark, as")
 (451977:452024, "God, who call'd him, in a land unknown. / CANAAN")
 (457966:458011, "From ABRAHAM, Son of ISAAC, and from him / His")
```

and so on.

## Crosswords usecase

Create some kind of crossword, e.g. from a striped pattern:
```julia-repl
julia> cw = striped_pattern(6, 8, seed=-53, min_stripe_dist=5)
    1  2  3  4  5  6  7  8 
  ┌────────────────────────┐
1 │ ■  .  .  .  .  .  ■  . │
2 │ .  .  .  .  .  ■  .  . │
3 │ .  .  .  ■  .  .  .  . │
4 │ .  .  .  .  ■  .  .  . │
5 │ .  .  ■  .  .  .  .  . │
6 │ .  ■  .  .  .  .  .  ■ │
  └────────────────────────┘
```

maybe add some words of your choice:
```julia-repl
julia> place_word!(cw, "Julia", 1, 8, :vertical)
true

julia> place_word!(cw, "Code", 4, 1, :horizontal)
true

julia> cw
    1  2  3  4  5  6  7  8
  ┌────────────────────────┐
1 │ ■  .  .  .  .  .  ■  J │
2 │ .  .  .  .  .  ■  .  U │
3 │ .  .  .  ■  .  .  .  L │
4 │ C  O  D  E  ■  .  .  I │
5 │ .  .  ■  .  .  .  .  A │
6 │ .  ■  .  .  .  .  .  ■ │
  └────────────────────────┘
```

Possibly save it to a file, so that if you want to fill it in automatically you have a "checkpoint" from which you can try different seeds for the words filling algorithm:
```julia-repl
julia> save_crossword(cw, "ex_docs.txt")
```

and finally fill it automatically:
```julia-repl
julia> fill!(cw, seed=-343); cw
    1  2  3  4  5  6  7  8 
  ┌────────────────────────┐
1 │ ■  B  R  E  A  D  ■  J │
2 │ P  I  E  R  S  ■  E  U │
3 │ A  R  N  ■  B  I  L  L │
4 │ C  O  D  E  ■  V  A  I │
5 │ E  N  ■  R  H  I  N  A │
6 │ R  ■  T  E  I  N  D  ■ │
  └────────────────────────┘
```

Smarter automatic algorithms (which e.g. can choose to place some useful black cells or to enlarge the grid) will soon be implemented, as well as semi-automatic ones where the user can choose which word to place among the possible ones or which action to take (placing a black cell, enlarging the grid, maybe removing a word, etc) at each step of the algorithm.