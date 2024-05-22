vim.api.nvim_create_autocmd({"WinEnter", "BufEnter"}, {
	group = vim.discordRPC.augroup,
	callback = function(ev)
		local filetype = vim.api.nvim_get_option_value("filetype", {buf=ev.buf})
		local large_image = filetype == "" and "https://cdn.jsdelivr.net/gh/EpicBirb/discord.nvim-assets@latest/icons/default_file.webp" or string.format("https://cdn.jsdelivr.net/gh/EpicBirb/discord.nvim-assets@latest/icons/file_type_%s.webp", filetype)
		vim.discordRPC:setActivity("Working on "..vim.fs.basename(vim.uv.cwd()), "Editing "..vim.fs.basename(ev.file), {
			start = vim.discordRPC.starttime
		}, {
			large_image = large_image,
			large_text = filetype == "" and "unknown" or (#filetype < 2 and filetype.."  " or filetype),
			small_image = "https://avatars.githubusercontent.com/neovim",
			small_text = "neovim"
		})
	end
})

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function(ev)
		vim.discordRPC:begin()
	end
})

vim.api.nvim_create_autocmd("VimLeave", {
	callback = function(ev)
		pcall(function() vim.discordRPC:disconnect() end)
	end
})
