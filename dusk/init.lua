local wnd = require 'wnd'
local keys = require 'keys'
local file = require 'file'
local git = require 'git'

vim.o.number = true
vim.o.relativenumber = true
vim.o.showtabline = 2

wnd.init {}

keys.init {
    struct = {
        ['q']  = keys.lvl { info = 'Quit', },
        ['qq'] = keys.vim { cmd = ':q', info = 'quit current', },
        ['qw'] = keys.vim { cmd = ':qw', info = 'save & quit current', },
        ['qa'] = keys.vim { cmd = ':wqa', info = 'save all & quit', },
        ['qz'] = keys.vim { cmd = ':qa!', info = 'discard & quit', },
        -- TODO view files not scaling just like all windows
        ['f']  = keys.act { act = file.view, info = 'view files', },
        ['p']  = keys.act { act = keys.show_tree, info = 'show key tree' },
    }
}

file.init {}
