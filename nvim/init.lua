--NOTE: this is an e2e demo configuration to add support for nushell inside neovim.
-- inspired by kickstart.nvim the idea is to show an example you can adapt to your own config.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

--ISSUE:: todo...

--INFO: Bootstrapping lazy (the package manager)
-- See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- INFO: settings to set nushell as the shell
vim.opt.shellredir = "--stdin < %s"
vim.opt.shellcmdflag = "-c"
vim.opt.shellquote = ""
vim.opt.shellxquote = " "
vim.opt.shellxescape = ""
vim.opt.sh = "nu"

-- NOTE: you can instead uncomment the following to for instance provide custom config paths
-- depending on the OS

-- utility method to detect the OS, if you use a custom config the following can be handy
-- local function getOS()
--   if jit then
--     return jit.os
--   end
--   local fh, err = assert(io.popen('uname -o 2>/dev/null', 'r'))
--   if fh then
--     Osname = fh:read()
--   end
--
--   return Osname or 'Windows'
-- end

-- if getOS() == 'Windows' then
--   vim.opt.sh = 'nu --env-config C:/Users/User/.dot/env/env.nu --config C:/Users/User/.dot/env/config.nu'
-- else
--   vim.opt.sh = 'nu --env-config /Users/mel/.dot/env/env.nu --config /Users/mel/.dot/env/config.nu'
-- end

require("lazy").setup({
	-- Color scheme
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},

	-- Highlight todo, notes, etc in comments
	{ "folke/todo-comments.nvim", dependencies = { "nvim-lua/plenary.nvim" }, opts = { signs = false } },

	-- Syntax highlighing, code navigation etc..
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",

		dependencies = "nushell/tree-sitter-nu",
		config = function()
			-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
			---@diagnostic disable-next-line: missing-fields
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"nu",
					"lua",
					"vim",
					"vimdoc",
				},
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	-- LSP
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
		},
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local servers = {
				lua_ls = {
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							workspace = {
								checkThirdParty = false,
								library = {
									"${3rd}/luv/library",
									unpack(vim.api.nvim_get_runtime_file("", true)),
								},
							},
						},
					},
				},
			}

			local ensure_installed = vim.tbl_keys(servers or {})
			require("mason").setup()
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			-- NOTE: nu --lsp setup taken from: https://github.com/amtoine/kickstart.nvim/blob/6aaa2f5f89156c30617a01ca8c73ce5cdd226302/lua/custom/nushell.lua#L81
			local lspconfig = require("lspconfig")
			local configs = require("lspconfig.configs")
			configs.nulsp = {
				default_config = {
					cmd = { "nu", "--lsp" },
					filetypes = { "nu" },
					root_dir = function(fname)
						local git_root = lspconfig.util.find_git_ancestor(fname)
						if git_root then
							return git_root
						else
							return vim.fn.fnamemodify(fname, ":p:h") -- get the parent directory of the file
						end
					end,
				},
			}
			lspconfig.nulsp.setup({ capabilities = capabilities })
			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						require("lspconfig")[server_name].setup({
							cmd = server.cmd,
							settings = server.settings,
							filetypes = server.filetypes,
							capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {}),
						})
					end,
				},
			})
		end,
	},
}, {})
