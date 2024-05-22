# discord.nvim

minimalist discord rich presence plugin for neovim (bordem) (code ~6kb, lua/ directory)

for those who want a working discord rich presence without any extra features or that you just want to clone the repository 
and implement the rest of your beautiful presence yourself

## unnecessary info and acknowledgments

for those who were looking where the icons went. go to <https://github.com/EpicBirb/discord.nvim-assets>

thanks to <https://github.com/iryont/lua-struct> for providing the code struct packing (although I did remove like the entire file and kept only what is nessesary)

also thanks to <https://cdn.jsdelivr.net> for providing free cdn service :D

contribute by making a pull request. I would probably expect changes to made for the presence or the api itself

## Installation

I mean you can just look up how you would normally install plugins for your specific package manager. Here is one for lazy.nvim (since I'm using that)

```lua
return {
    "EpicBirb/discord.nvim",
    lazy = false
}
```

## For those who want to implement their own presence

ight, heres what you need to do

1. call `vim.discordRPC:disableDefaultEvents()`

that's it. the rest is up to you. use `vim.discordRPC:setActivity` to set your presence. api is included in the help doc.

<h6>made with bordem and constant runtime errors that had to be fixed without type checking by EpicBirb (lol)</h6>