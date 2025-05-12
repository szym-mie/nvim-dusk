local M = {}

local u = require 'u'
local wnd = require 'wnd'
local vis = require 'vis'
local cmd = require 'cmd'

local alt_key_chars = {
    [' '] = 'space',
    ['['] = ' [ ',
    [']'] = ' ] ',
}

local all_key_chars = {}
all_key_chars[' '] = 32
all_key_chars['['] = 91
all_key_chars[']'] = 93
all_key_chars[','] = 44
all_key_chars['.'] = 46
all_key_chars['-'] = 45
all_key_chars['='] = 61
for i = 65, 90 do
    local key = string.char(i)
    all_key_chars[key] = i
end
for i = 97, 122 do
    local key = string.char(i)
    all_key_chars[key] = i
end

local function escape_key_chain(key_chain)
    local key_chars = ''
    for key in key_chain:gmatch('.') do
        local key_char = alt_key_chars[key] or key
        key_chars = key_chars .. key_char
    end
    return '[' .. key_chars .. ']'
end

local function key_chain_path(key_chain)
    return '<space>' .. key_chain
end

local function bind_on_key(key_chain, key_action)
    vim.keymap.set('n', key_chain_path(key_chain), key_action)
end

local function new_level()
    return { type = 'lvl', info = 'no-info', lvl = {}, }
end

local function walk_level(level, base, act_func, lvl_func, nil_func)
    for key, _ in pairs(all_key_chars) do
        local entry = level.lvl[key]
        local base_key = base .. key
        if entry == nil then
            nil_func(base_key)
        else
            if entry.type == 'lvl' then
                lvl_func(base_key, entry)
                walk_level(entry, base_key, act_func, lvl_func, nil_func)
            end
            if entry.type == 'act' then
                act_func(base_key, entry)
            end
        end
    end
end

local function walk_tree(tree, act_func, lvl_func, nil_func)
    walk_level(tree, '', act_func, lvl_func, nil_func)
end

local function merge_in_tree(tree, key_chain, entry, merge_func)
    local level = tree
    local depth = 0
    local limit = #key_chain - 1
    for key in key_chain:gmatch('.') do
        if level.type == 'lvl' then
            if depth < limit then
                local next_level = level.lvl[key]
                if next_level == nil then
                    -- lazily create level
                    level.lvl[key] = new_level()
                    next_level = level.lvl[key]
                end
                level = next_level
            else
                local prev_entry = level.lvl[key]
                if prev_entry == nil then
                    level.lvl[key] = entry
                else
                    level.lvl[key] = merge_func(prev_entry, entry)
                end
            end
        else
            error('cannot merge entry: unexpected end of chain')
        end

        depth = depth + 1
    end
end

local function put_entry(key_chain, entry)
    local merge_func = nil
    if entry.type == 'lvl' then
        merge_func = function(p, n)
            p.info = n.info
            return p
        end
    end
    if entry.type == 'act' then
        merge_func = function(_, n)
            return n
        end
    end
    merge_in_tree(M.tree, key_chain, entry, merge_func)
end

local function new_act_help(key_chain, level)
    return function()
        local text_key_chain = escape_key_chain(key_chain)
        wnd.rename(M.help_wnd, text_key_chain .. ' map')
        wnd.bind(M.help_wnd, level)
        wnd.show(M.help_wnd)
    end
end

local function new_act_undef(key_chain)
    return function()
        local text_key_chain = escape_key_chain(key_chain)
        wnd.rename(M.undef_wnd, text_key_chain .. ' - undef')
        wnd.bind(M.undef_wnd, ' unknown command ' .. text_key_chain)
        wnd.render(M.undef_wnd)
        wnd.show(M.undef_wnd)
    end
end

local function setup_action(key_chain, action)
    bind_on_key(key_chain, action.act)
end

local function setup_level(key_chain, level)
    bind_on_key(key_chain, new_act_help(key_chain, level.lvl))
end

local function setup_nil(key_chain)
    bind_on_key(key_chain, new_act_undef(key_chain))
end

local function close_wnds()
    wnd.hide(M.help_wnd)
    wnd.hide(M.undef_wnd)
end

local function level_to_items(level)
    local entries = {}
    for key, entry in pairs(level) do
        table.insert(entries, { key = key, entry = entry, })
    end
    table.sort(entries, function(a, b)
        if a.entry.type == b.entry.type then
            return a.key < b.key
        else
            return a.entry.type == 'lvl'
        end
    end)
    local items = {}
    for _, entry in ipairs(entries) do
        local key = escape_key_chain(entry.key)
        local pre = '  '
        if entry.entry.type == 'lvl' then
            pre = ' +'
        end
        local info = entry.entry.info or ''
        local item = key .. pre .. info
        table.insert(items, item)
    end
    return items
end

function M.show_tree()
    u.printx(M.tree)
end

-- TODO not a race condition per-se, when 'q' is first and its children follow,
-- you get such a mess

function M.init(opts)
    local struct = opts.struct or {}
    M.tree = new_level()
    for key, entry in pairs(struct) do
        put_entry(key, entry)
    end
    walk_tree(M.tree, setup_action, setup_level, setup_nil)
    setup_level('', M.tree)

    M.help_wnd = wnd.new {
        id = 'keys:help',
        pos = { x = '0u', y = '0u', },
        size = { x = '100%', y = '3u', },
        title = 'key-help',
        anchor = 'SW',
        render = vis.fixed_cols(4, level_to_items),
        input = false,
    }
    M.undef_wnd = wnd.new {
        id = 'keys:undef',
        pos = { x = '0u', y = '0u', },
        size = { x = '30u', y = '1u', },
        title = 'key-undef',
        anchor = 'SW',
        render = vis.plain_text(),
        input = false,
    }

    vim.on_key(close_wnds)
end

function M.lvl(opts)
    local info = opts.info
    return {
        type = 'lvl',
        info = info,
        lvl = {},
    }
end

function M.act(opts)
    local info = opts.info
    local act = opts.act
    return {
        type = 'act',
        info = info,
        act = act,
    }
end

local function dpy_sink(_) end

function M.vim(opts)
    local info = opts.info
    local vim_cmd = opts.cmd
    local dpy_func = opts.dpy or dpy_sink
    return {
        type = 'act',
        info = info,
        act = function() dpy_func(cmd.exec_vim(vim_cmd)) end,
    }
end

return M
