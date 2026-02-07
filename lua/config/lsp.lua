vim.diagnostic.config({
    virtual_text  = true,
    severity_sort = true,
    float         = {

        style  = 'minimal',
        border = 'rounded',
        source = 'if_many',
        header = '',
        prefix = '',
    },
    signs         = {
        text = {

            [vim.diagnostic.severity.ERROR] = '✘',
            [vim.diagnostic.severity.WARN]  = '▲',
            [vim.diagnostic.severity.HINT]  = '⚑',
            [vim.diagnostic.severity.INFO]  = '»',
        },
    },
})

-- Works best with completeopt=noselect.
-- Use CTRL-Y to select an item. |complete_CTRL-Y|
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
