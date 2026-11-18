require("config.options")
require("config.keybinds")
require("config.lazy")
require("config.lsp")

vim.lsp.enable('pyright')
vim.lsp.enable('arduino')
vim.lsp.enable('rust_glancer')
-- vim.lsp.enable('clangd')
