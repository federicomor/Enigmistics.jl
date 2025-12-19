push!(LOAD_PATH,"../src/")
using Documenter, Enigmistics

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
    remotes = nothing
)