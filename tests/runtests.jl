using Test
using .Enigmistics

@testset "Tinkering with crosswords" begin
    cw = example_crossword(type="full")
    @test remove_word!(cw, "dog") == false # word not present
    @test remove_word!(cw, "so") == false # word not present
    @test remove_word!(cw, "window") == true
    @test remove_word!(cw, "narrow") == true 
    @test remove_word!(cw, "door") == true

    @test can_place_word(cw, "dior", 1,4,:vertical) == true
    @test can_place_word(cw, "DIOR", 1,4,:vertical) == true # should be case insensitive
    @test can_place_word(cw, "d.or", 1,4,:vertical) == false # should only accept letters
    @test can_place_word(cw, "dior", 1,4,:horizontal) == false    
end