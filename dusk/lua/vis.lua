local M = {}

local u = require 'u'

local space = ' '
local nl_sep = '\r\n'

local function set_buf(wnd, lines)
    u.defer(function()
        vim.api.nvim_buf_set_lines(wnd.buf_id, 0, -1, false, {})
        vim.api.nvim_buf_set_lines(wnd.buf_id, 0, -1, false, lines)
    end)
end

function M.fixed_cols(cols, to_items_func)
    return function(wnd, body)
        local items = to_items_func(body)
        local line_count = math.ceil(#items / cols)
        local lines = u.times(line_count, u.const(''))
        local col_size = math.floor(wnd.int.size.x / cols) - 1
        local i = 1
        for _, item in ipairs(items) do
            local text = u.fixed_len_text(item, col_size, ' ', '/')
            lines[i] = lines[i] .. space .. text
            if i < line_count then
                i = i + 1
            else
                i = 1
            end
        end
        set_buf(wnd, lines)
    end
end

function M.plain_text()
    return function(wnd)
        local lines = u.split_text(wnd.body, nl_sep)
        set_buf(wnd, lines)
    end
end

function M.center()
    return function(wnd)

    end
end

return M
