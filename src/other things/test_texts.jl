text = clean_read("../texts/tragedie_inni_sacri_odi.txt", newline_replace="/")
text = clean_read("../texts/alice_in_wonderland.txt", newline_replace="/")

scan_for_pangrams(text, max_length_letters=100, language="en")
scan_for_heterograms(text, min_length_letters=13)
scan_for_lipograms(text, "tn"; min_length_letters=40, max_length_letters=100)
scan_for_anagrams(text; min_length_letters=10, max_length_letters=30, max_distance_words=20)
scan_for_palindromes(text; min_length_letters=6,  max_length_letters=30)

