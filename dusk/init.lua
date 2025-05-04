local wnd = require 'wnd'
local keys = require 'keys'

vim.o.number = true
vim.o.relativenumber = true
vim.o.showtabline = 2

wnd.init {}

keys.init {
    struct = {
        ['q']  = keys.lvl { info = 'Quit' },
        ['qq'] = keys.cmd { cmd = ':wqa', info = 'save all & quit' },
        ['l']  = keys.cmd { cmd = ':ls', info = 'list buffers' },
    }
}
