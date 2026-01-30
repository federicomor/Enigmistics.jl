using Pkg
Pkg.activate(".")
using ProgressMeter, Logging
# cd("src/")

include("../Wordgames/_constants.jl")
include("../Wordgames/_text_utils.jl")
include("../Wordgames/pangrams.jl")
include("../Wordgames/anagrams.jl")
include("../Wordgames/heterograms.jl")
include("../Wordgames/palindromes.jl")
include("../Wordgames/lipograms.jl")
include("../Wordgames/tautograms.jl")
include("../Wordgames/abecedaries.jl")


include("../Crosswords/grid_utils.jl")
include("../Crosswords/crosswords.jl")
include("../Crosswords/io.jl")
include("../Crosswords/dictionary.jl")

# include("Enigmistics.jl")