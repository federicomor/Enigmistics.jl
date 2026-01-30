text = clean_read("AAA.txt", newline_replace="/")

scan_for_abecedaries(text, min_length_words=4, max_length_words=5, language="en")
scan_for_anagrams(text; min_length_letters=10, max_length_letters=30, max_distance_words=20)
scan_for_heterograms(text, min_length_letters=13)
scan_for_lipograms(text, "EN"; min_length_letters=40, max_length_letters=100)
scan_for_palindromes(text; min_length_letters=6,  max_length_letters=30)
scan_for_pangrams(text, max_length_letters=100, language="en")
scan_for_tautograms(text, min_length_words=4, max_length_words=20)

