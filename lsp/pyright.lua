vim.cmd[[set completeopt+=menuone,noselect,popup]]
vim.lsp.start({
  name = 'pyright',
  cmd = { 'pyright-langserver', '--stdio' },
  on_attach = function(client, bufnr)
    vim.lsp.completion.enable(true, client.id, bufnr, {
      autotrigger = true,
      convert = function(item)
        return { abbr = item.label:gsub('%b()', '') }
      end,
    })
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local buf    = args.buf
    local map    = function(mode, lhs, rhs) vim.keymap.set(mode, lhs, rhs, { buffer = buf }) end

    map('n', 'K', vim.lsp.buf.hover)
    map('n', 'gd', vim.lsp.buf.definition)
    map('n', 'gD', vim.lsp.buf.declaration)
    map('n', 'gi', vim.lsp.buf.implementation)
    map('n', 'go', vim.lsp.buf.type_definition)
    map('n', 'gr', vim.lsp.buf.references)
    map('n', 'gs', vim.lsp.buf.signature_help)
    map('n', 'gl', vim.diagnostic.open_float)
    map('i', '<c-@>', function() vim.lsp.completion.get() end)
    --        map('n', '<F2>', vim.lsp.buf.rename)
    --        map({ 'n', 'x' }, '<F3>', function() vim.lsp.buf.format({ async = true }) end)
    --        map('n', '<F4>', vim.lsp.buf.code_action)

    local excluded_filetypes = { php = true, c = true, cpp = true }
    if not client:supports_method('textDocument/willSaveWaitUntil')
      and client:supports_method('textDocument/formatting')
      and not excluded_filetypes[vim.bo[buf].filetype]
    then
      vim.api.nvim_create_autocmd('BufWritePre', {
	group = vim.api.nvim_create_augroup('my.lsp.format', { clear = false }),
	buffer = buf,
	callback = function()
	  vim.lsp.buf.format({ bufnr = buf, id = client.id, timeout_ms = 1000 })
	end,
      })
    end
  end,
})


---@brief
---
--- https://github.com/microsoft/pyright
---
--- `pyright`, a static type checker and language server for python

local function set_python_path(command)
  local path = command.args
  local clients = vim.lsp.get_clients {
    bufnr = vim.api.nvim_get_current_buf(),
    name = 'pyright',
  }
  for _, client in ipairs(clients) do
    if client.settings then
      client.settings.python =
      vim.tbl_deep_extend('force', client.settings.python --[[@as table]], { pythonPath = path })
    else
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
    end
    client:notify('workspace/didChangeConfiguration', { settings = nil })
  end
end

---@type vim.lsp.Config
return {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyrightconfig.json',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  settings = {
    python = {
      analysis = {
	autoSearchPaths = true,
	useLibraryCodeForTypes = true,
	diagnosticMode = 'openFilesOnly',
      },
    },
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
      local params = {
	command = 'pyright.organizeimports',
	arguments = { vim.uri_from_bufnr(bufnr) },
      }

      -- Using client.request() directly because "pyright.organizeimports" is private
      -- (not advertised via capabilities), which client:exec_cmd() refuses to call.
      -- https://github.com/neovim/neovim/blob/c333d64663d3b6e0dd9aa440e433d346af4a3d81/runtime/lua/vim/lsp/client.lua#L1024-L1030
      ---@diagnostic disable-next-line: param-type-mismatch
      client.request('workspace/executeCommand', params, nil, bufnr)
    end, {
	desc = 'Organize Imports',
      })
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
      desc = 'Reconfigure pyright with the provided python path',
      nargs = 1,
      complete = 'file',
    })
  end,
}
