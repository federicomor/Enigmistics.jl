# julia --color=yes --project make.jl
push!(LOAD_PATH,"../src/")
using Enigmistics, Documenter

DocMeta.setdocmeta!(Enigmistics, :DocTestSetup, :(using Enigmistics); recursive=true)

makedocs(
    sitename = "Enigmistics",
    format = Documenter.HTML(
        # repolink = "https://github.com/federicomor/Enigmistics",
        repolink = "...",
        inventory_version = "0.1.0"
    ),  
    pages = [
        "index.md",
        "wordgames.md",
        "crosswords.md"
        ],
    modules = [Enigmistics], doctest = true, checkdocs=:exports,
    remotes = nothing
)