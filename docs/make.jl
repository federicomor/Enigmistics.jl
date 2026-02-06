# julia --color=yes --project make.jl
push!(LOAD_PATH,"../src/")
using Enigmistics, Documenter

DocMeta.setdocmeta!(Enigmistics, :DocTestSetup, :(using Enigmistics); recursive=true)

makedocs(
    sitename = "Enigmistics.jl",
    repo="https://github.com/federicomor/Enigmistics.jl",
    format = Documenter.HTML(
        prettyurls=false,
        repolink = GitHub("federicomor", "Enigmistics.jl")
        # repolink = "...", # if testing locally?
        # inventory_version = "0.1.0" # if testing locally?
    ),  
    modules = [Enigmistics], doctest = true, # run doctests
    checkdocs=:exports, # check for docstrings only on exported functions
    pages = [
        "Home" =>"index.md",
        "Wordgames" => "wordgames.md",
        "Crosswords" => "crosswords.md"
        ]
    # remotes = nothing # if testing locally?
)

deploydocs(
    repo = "github.com/federicomor/Enigmistics.jl",
    devbranch = "main",
    branch = "gh-pages",
    versions = nothing
)