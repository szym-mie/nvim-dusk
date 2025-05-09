local M = {}

function M.defer(func)
    vim.schedule(func)
end

function M.const(v)
    return function(_)
        return v
    end
end

function M.times(n, item_func)
    local array = {}
    for i = 0, n do
        table.insert(array, item_func(i))
    end
    return array
end

function M.fixed_len_text(text, len, space, post)
    local max_len = len - #post
    local text_len = #text
    local remain = len - text_len
    if text_len <= len then
        return text .. space:rep(remain)
    else
        return text:sub(0, max_len) .. post
    end
end

function M.split_text(text, sep)
    local lines = {}
    for line in text:gmatch('[^' .. sep .. ']+') do
        table.insert(lines, line)
    end
    return lines
end

return M
