using Pkg
Pkg.activate(".")
using ProgressMeter
cd("src/")

include("Wordgames/constants.jl")
include("Wordgames/text_utils.jl")
include("Wordgames/pangrams.jl")
include("Wordgames/anagrams.jl")
include("Wordgames/heterograms.jl")
include("Wordgames/palindromes.jl")
include("Wordgames/lipograms.jl")

