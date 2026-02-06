# Enigmistics

Enigmistics.jl is a Julia package for exploring and analyzing language puzzles, in particular: crosswords and wordgames. More precisely, this package provides utilities for

- working with crosswords. You can create, edit, save/load crosswords, enlarge existing ones, creating random or more regular (i.e. striped) patterns of black cells. Most importantly, with Enigmistics.jl you can fill in the words of an empty or partially complete crossword either fully automatically or manually, thanks to some some auxiliary functions which highlight the more constrained slots, by which the algorithm (if automatically) or one (if manually) should start from. Available words can be taken from dictionaries; currently supported ones are english and italian. 

- efficiently finding wordgames in texts. Currently, the supported wordgames are abecedaries, anagrams, heterograms, lipograms, palindromes, pangrams, tautograms. For each of them, two functions are provided: one to check if a given text satisfies the wordgame constraints (functions `is_pangram`, `is_palindrome`, etc), and one to find all substrings from a given text which satisfy the wordgame constraints (functins `scan_for_pangrams`, `scan_for_palindromes`, etc).

