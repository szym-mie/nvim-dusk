local M = {}

local cmd = require 'cmd'
local wnd = require 'wnd'

function M.init(_)
    vim.g.netrw_banner = 0
    vim.g.netrw_altv = 1
    vim.g.netrw_browse_split = 4
    vim.g.netrw_liststyle = 4
    vim.g.netrw_winsize = 14
    vim.g.netrw_clipboard = 0

    M.view_wnd = wnd.new {
        id = 'file:view',
        pos = { x = '0u', y = '10%', },
        size = { x = '50%', y = '80%', },
        title = 'view dir',
        anchor = 'NE',
    }
end

function M.view()
    if not M.view_wnd.show then
        wnd.show(M.view_wnd)
        wnd.focus(M.view_wnd)
        cmd.exec_vim(':Ex')
    else
        wnd.hide(M.view_wnd)
    end
end

return M
