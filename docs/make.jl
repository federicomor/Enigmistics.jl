# julia --color=yes --project make.jl
push!(LOAD_PATH,"../src/")
using Enigmistics, Documenter

DocMeta.setdocmeta!(Enigmistics, :DocTestSetup, :(using Enigmistics); recursive=true)

makedocs(
    sitename = "Enigmistics.jl",
    format = Documenter.HTML(
        repolink = "https://github.com/federicomor/Enigmistics",
        # repolink = "...", # if testing locally
        inventory_version = "0.1.0"
    ),  
    modules = [Enigmistics], doctest = true, # run doctests
    checkdocs=:exports, # check for docstrings only on exported functions
    pages = [
        "index.md",
        "wordgames.md",
        "crosswords.md"
        ],
    remotes = nothing
)

deploydocs(
    repo = "github.com/federicomor/Enigmistics.jl.git",
    versions = nothing
)