using Pkg
Pkg.activate(".")
using ProgressMeter
# cd("src/")

include("Wordgames/constants.jl")
include("Wordgames/text_utils.jl")
include("Wordgames/pangrams.jl")
include("Wordgames/anagrams.jl")
include("Wordgames/heterograms.jl")
include("Wordgames/palindromes.jl")
include("Wordgames/lipograms.jl")


include("Crosswords/grid_utils.jl")
include("Crosswords/crosswords.jl")
include("Crosswords/io.jl")

# include("Enigmistics.jl")