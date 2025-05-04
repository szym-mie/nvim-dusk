local M = {}

local wnd = require 'wnd'
local vis = require 'vis'

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

local function init_key_action(key_chain, key_action)
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
                    next_level = new_level()
                    level.lvl[key] = next_level
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

local function get_in_tree(tree, key_chain)
    local level = tree
    for key in key_chain:gmatch('.') do
        if level == nil then
            return nil
        end
        level = level[key]
    end
    return level
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
    print('merge ' .. entry.type)
    merge_in_tree(M.tree, key_chain, entry, merge_func)
end

local function new_act_undef(key_chain)
    return function()
        local text_key_chain = escape_key_chain(key_chain)
        print('unknown command ' .. text_key_chain)
    end
end

local function new_act_help(key_chain, level)
    return function()
        local text_key_chain = escape_key_chain(key_chain)
        wnd.rename(M.help_wnd, text_key_chain .. ' map')
        wnd.bind(M.help_wnd, level)
        wnd.show(M.help_wnd)
        wnd.render(M.help_wnd)
    end
end

local function setup_action(key_chain, action)
    init_key_action(key_chain, action.act)
end

local function setup_level(key_chain, level)
    print(key_chain .. ' ' .. level.info)
    init_key_action(key_chain, new_act_help(key_chain, level))
end

local function setup_nil(key_chain)
    init_key_action(key_chain, new_act_undef(key_chain))
end

local function close_wnds()
    wnd.hide(M.help_wnd)
end

local function level_to_items(level)
    local entries = {}
    for key, entry in pairs(level.lvl) do
        entry.key = key
        table.insert(entries, entry)
    end
    table.sort(entries, function(a, b)
        if a.type == b.type then
            return a.key < b.key
        else
            return a.type == 'lvl'
        end
    end)
    local items = {}
    for _, entry in ipairs(entries) do
        local item = escape_key_chain(entry.key)
        if entry.type == 'lvl' then
            item = item .. ' +' .. entry.info
            print(item)
        end
        if entry.type == 'act' then
            item = item .. ' ' .. entry.info
            print(item)
        end
        table.insert(items, item)
    end
    return items
end

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
        size = { x = '100%', y = '8u', },
        title = 'key-help',
        render = vis.fixed_cols(4, level_to_items)
    }
    -- vim.on_key(close_wnds)
end

function M.lvl(opts)
    local info = opts.info
    return {
        type = 'lvl',
        info = info,
        lvl = new_level(),
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

function M.cmd(opts)
    local info = opts.info
    local cmd = opts.cmd
    return {
        type = 'act',
        info = info,
        act = function() pcall(vim.cmd(cmd)) end,
    }
end

return M
