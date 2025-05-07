local M = {}

local space = ' '

local function const(v)
    return function(_)
        return v
    end
end

local function times(n, item_func)
    local array = {}
    for i = 0, n do
        table.insert(array, item_func(i))
    end
    return array
end

local function fixed_len_text(text, len, post)
    local max_len = len - #post
    local text_len = #text
    local remain = len - text_len
    if text_len <= len then
        return text .. space:rep(remain)
    else
        return text:sub(0, max_len) .. post
    end
end

local nl_sep = '\r\n'

local function split_text(text, sep)
    local lines = {}
    for line in text:gmatch('[^' .. sep .. ']+') do
        table.insert(lines, line)
    end
    return lines
end

local function set_buf(wnd, lines)
    vim.api.nvim_buf_set_lines(wnd.buf_id, 0, -1, false, lines)
end

function M.fixed_cols(cols, to_items_func)
    return function(wnd)
        local items = to_items_func(wnd.body or {})
        local line_count = math.ceil(#items / cols)
        local lines = times(line_count, const(''))
        local col_size = math.floor(wnd.int.size.x / cols) - 1
        local i = 1
        for _, item in ipairs(items) do
            lines[i] = lines[i] .. space .. fixed_len_text(item, col_size, '/')
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
        local lines = split_text(wnd.body, nl_sep)
        set_buf(wnd, lines)
    end
end

function M.center()
    return function(wnd)

    end
end

return M
