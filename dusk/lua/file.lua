local M = {}

function M.init(_)
    vim.g.netrw_banner = 0
    vim.g.netrw_altv = 1
    vim.g.netrw_browse_split = 4
    vim.g.netrw_liststyle = 4
    vim.g.netrw_winsize = 14
    vim.g.netrw_clipboard = 0
end

return M
