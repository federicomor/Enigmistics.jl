text = clean_read("texts/alice_in_wonderland.txt", newline_replace="/");
text = clean_read("texts/all_shakespeare.txt", newline_replace="/");
text = clean_read("texts/brothers_karamazov.txt", newline_replace="/");
text = clean_read("texts/crime_and_punishment.txt", newline_replace="/");
text = clean_read("texts/decameron_en.txt", newline_replace="/");
text = clean_read("texts/decameron_it.txt", newline_replace="/");
text = clean_read("texts/divina_commedia.txt", newline_replace="/");
text = clean_read("texts/orlando_furioso.txt", newline_replace="/");
text = clean_read("texts/paradise_lost.txt", newline_replace="/");
text = clean_read("texts/pride_and_prejudice.txt", newline_replace="/");
text = clean_read("texts/promessi_sposi.txt", newline_replace="/");
text = clean_read("texts/tragedie_inni_sacri_odi.txt", newline_replace="/");

texts = [
# "alice_in_wonderland.txt",
# "all_shakespeare.txt",
# "brothers_karamazov.txt",
# "crime_and_punishment.txt",
# "decameron_en.txt",
    # "decameron.txt",
    "divina_commedia.txt",
    "orlando_furioso.txt",
# "paradise_lost.txt",
# "pride_and_prejudice.txt",
    "promessi_sposi.txt",
    "canzoniere.txt",
# "tragedie_inni_sacri_odi.txt"
]

scan_for_anagrams(text, min_length_letters=9, max_length_letters=14, max_distance_words=10, be_strict=true)
scan_for_pangrams(text, max_length_letters=50, language="it")
scan_for_palindromes(text,  min_length_letters=6)
scan_for_heterograms(text, min_length_letters=13)
scan_for_lipograms(text, "e", min_length_letters=97)

printstyled("\n==== Eterogrammi: sequenze di parole senza lettere ripetute ====\n", bold=true)
for t in texts
    text = clean_read("texts/$t", newline_replace="/");
    println("---- $t ----")
    # scan_for_lipograms(text, "e", min_length_letters=95, print_results=true);
    scan_for_heterograms(text, min_length_letters=13, print_results=true);
end

printstyled("\n==== Tautogrammi: sequenze di parole che cominciano con la stessa lettera ====\n", bold=true )
for t in texts
    text = clean_read("texts/$t", newline_replace="/");
    println("---- $t ----")
    scan_for_tautograms(text, min_length_words= t=="divina_commedia.txt" || t=="canzoniere.txt" ? 4 : 5, max_length_words=20, print_results=true);
end

text = clean_read("texts/divina_commedia.txt", newline_replace="/");

printstyled("\n==== Pangrammi: sequenze di parole che contengono tutte le lettere dell'alfabeto ====\n", bold=true )
for t in texts
    text = clean_read("texts/$t", newline_replace="/");
    println("---- $t ----")
    scan_for_pangrams(text, max_length_letters=48, language="it", print_results=true);
end

printstyled("\n==== Abbecedari: sequenze di parole le cui iniziali sono in ordine alfabetico ====\n", bold=true )
for t in texts
    text = clean_read("texts/$t", newline_replace="/");
    println("---- $t ----")
    scan_for_abecedaries(text, min_length_words=4, max_length_words=6, language="it", print_results=true);
end

t = "decameron.txt"
text = clean_read("texts/$t", newline_replace="/");
println("---- $t ----")
scan_for_abecedaries(text, min_length_words=4, max_length_words=6, language="it", print_results=true);