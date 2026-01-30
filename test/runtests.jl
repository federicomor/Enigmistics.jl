using Enigmistics
using Test

@testset "Abecedaries" begin
    # italian example
    @test is_abecedary("Amore baciami! Con dolci effusioni fammi 
                gioire! Ho illibate labbra, meraviglioso nido ove puoi 
                quietare recondita sensualità traboccante. Ubriachiamoci 
                vicendevolmente, Zaira!", language="it") == true
    # english example
    @test is_abecedary("A Bright Celestial Dawn Emerges") == true

    # weird stuff between words
    @test is_abecedary("Love me! :) ...??? Not -- only ") == true

    # accents should not matter
    @test is_abecedary("à b c", language="it") == true
    @test is_abecedary("à b c d è f", language="it") == true
    @test is_abecedary("À B C d É F", language="it") == true
    
    # wrap around the alphabet
    @test is_abecedary("Testing: u v w x y z a b c") == true
    @test is_abecedary("Testing: u v z a b c", language="it") == true
end

@testset "Anagrams" begin
    # accents should not matter
    @test are_anagrams("èèè","eee", be_strict=false) == true
    @test are_anagrams("ÀÌÙ","aiù", be_strict=false) == true

    # true anagram
    @assert true == are_anagrams("The Morse Code","Here come dots!") 
    # just a fancy reordering
    @assert false == are_anagrams("The Morse Code","Morse: the code!")
    # just a fancy reordering, but not being strict
    @assert true == are_anagrams("The Morse Code","Morse: the code!", be_strict=false)
end

@testset "Heterograms" begin
    # docs examples
    @assert false == is_heterogram("unpredictable") # letter 'e' is repeated
    @assert true == is_heterogram("unpredictably")
    @assert true == is_heterogram("The big dwarf only jumps")

    # accents should not matter
    @assert is_heterogram("èai") == true
    @assert is_heterogram("èée") == false
end

@testset "Lipograms" begin
    # docs examples
    @test is_lipogram("This is a small thought without using a famous symbol following D","e") == true
    @test is_lipogram("The quick brown fox","abc") == false

    # accents should not matter, both in input string a wrt string
    @test is_lipogram("ÒÈA","a") == false
    @test is_lipogram("ÒÈ","A") == true
    @test is_lipogram("ÒÈA","à") == false
    @test is_lipogram("ÒÈ","À") == true
end

@testset "Palindromes" begin
    # docs examples
    @test is_palindrome("Oozy rat in a sanitary zoo") == true
    @test is_palindrome("Alle carte t'alleni nella tetra cella") == true

    # accents or other characters should not matter
    @test is_palindrome("ànna") == true
    @test is_palindrome("èké") == true
    @test is_palindrome("è ... 123 !!é") == true
end

@testset "Pangrams" begin
    # english examle
    @test is_pangram("The quick brown fox jumps over the lazy dog") == true
    @test is_pangram("The slow brown fox jumps over the lazy dog") == false
    # italian example
    @test is_pangram("Pranzo d'acqua fa volti sghembi", language="it") == true
    @test is_pangram("Pranzo d'acqua fa visi sghembi", language="it") == false

    # accents should not matter
    @test is_pangram("àbcdèfghìjklMnÒPQRSTÙVZ", language="it") == true
    @test is_pangram("àbcdèfghìlMnÒPQRSTÙVZ", language="it") == true
end

@testset "Tautograms" begin
    # docs example
    @test is_tautogram("Disney declared: 'Donald Duck definitely deserves devotion'") == true
    @test is_tautogram("She sells sea shells by the sea shore.") == false

    # accents should not matter
    @test is_tautogram("É èh e ecc è! ECC") == true
end



# @testset "Tinkering with crosswords" begin
#     cw = example_crossword(type="full")
#     @test remove_word!(cw, "dog") == false # word not present
#     @test remove_word!(cw, "so") == false # word not present
#     @test remove_word!(cw, "window") == true
#     @test remove_word!(cw, "narrow") == true 
#     @test remove_word!(cw, "door") == true

#     @test can_place_word(cw, "dior", 1,4,:vertical) == true
#     @test can_place_word(cw, "DIOR", 1,4,:vertical) == true # should be case insensitive
#     @test can_place_word(cw, "d.or", 1,4,:vertical) == false # should only accept letters
#     @test can_place_word(cw, "dior", 1,4,:horizontal) == false    
# end