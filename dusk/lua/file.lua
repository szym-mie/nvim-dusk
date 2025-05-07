local M = {}

local cmd = require 'cmd'

function M.init(opts)
    vim.g.netrw_banner = 0
    vim.g.netrw_altv = 1
    vim.g.netrw_browse_split = 4
    vim.g.netrw_liststyle = 4
    vim.g.netrw_winsize = 14
    if opts.show then
        cmd.exec_vim(':Lex')
    end
end

return M
