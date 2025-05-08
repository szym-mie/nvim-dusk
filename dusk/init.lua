local wnd = require 'wnd'
local keys = require 'keys'
local file = require 'file'

vim.o.number = true
vim.o.relativenumber = true
vim.o.showtabline = 2

wnd.init {}

keys.init {
    struct = {
        ['q']  = keys.lvl { info = 'Quit' },
        ['qq'] = keys.vim { cmd = ':wq', info = 'quit current window' },
        ['qa'] = keys.vim { cmd = ':wqa', info = 'save all & quit' },
        ['qd'] = keys.vim { cmd = ':qa!', info = 'discard & quit' },
        ['f']  = keys.act { act = file.view, info = 'view files' },
    }
}

file.init {}
