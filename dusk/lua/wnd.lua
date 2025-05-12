local M = {}

local u = require 'u'

local function parse_vec_comp(comp)
    local num = tonumber(comp:match('^%-?%d+'))
    if num < 0 then
        error('negative vec component')
    end
    if comp:match('u$') ~= nil then
        return { ref = 'abs', val = num, }
    end
    if comp:match('%%$') ~= nil then
        return { ref = 'pct', val = num * 0.01, }
    end
    error('unknown vec unit in ' .. comp)
end

local function parse_vec(vec)
    return {
        x = parse_vec_comp(vec.x),
        y = parse_vec_comp(vec.y),
    }
end

local function on_screen_update()
    M.scr_size = {
        x = vim.o.columns,
        y = vim.o.lines,
    }
    M.update_all()
end

local anchor_align_sub = {
    NW = { x = 0, y = 0, },
    NE = { x = 1, y = 0, },
    SW = { x = 0, y = 1, },
    SE = { x = 1, y = 1, },
}

local function calc_int_size_comp(sub, comp, scr_size_comp)
    local ref = comp.ref
    local val = comp.val
    if ref == 'abs' then
        return math.floor(val)
    end
    if ref == 'pct' then
        return math.floor(scr_size_comp * val)
    end
    error('unknown size reference ' .. ref)
end

local function calc_int_pos_comp(sub, comp, scr_size_comp)
    local ref = comp.ref
    local val = comp.val
    if ref == 'abs' then
        if sub == 1 then
            return scr_size_comp - val - 1
        else
            return val
        end
    end
    if ref == 'pct' then
        if sub == 1 then
            return scr_size_comp * (1.0 - val)
        else
            return scr_size_comp * val
        end
    end
    error('unknown pos reference ' .. ref)
end

local function update_wnd(wnd)
    local sx = M.scr_size.x
    local sy = M.scr_size.y
    local sub = anchor_align_sub[wnd.anchor]

    wnd.int = {
        size = {
            x = calc_int_size_comp(sub.x, wnd.size.x, sx),
            y = calc_int_size_comp(sub.y, wnd.size.y, sy),
        },
        pos = {
            x = calc_int_pos_comp(sub.x, wnd.pos.x, sx),
            y = calc_int_pos_comp(sub.y, wnd.pos.y, sy),
        },
    }
end

local function get_wnd_opts(wnd)
    if wnd.int == nil then
        update_wnd(wnd)
    end
    print('== ' .. wnd.title)
    print(wnd.int.pos.x)
    print(wnd.int.pos.y)
    print(wnd.int.size.x)
    print(wnd.int.size.y)
    local wnd_opts = {
        col = wnd.int.pos.x,
        row = wnd.int.pos.y,
        width = wnd.int.size.x,
        height = wnd.int.size.y,
        anchor = wnd.anchor,
        title = ' ' .. wnd.title .. ' ',
        title_pos = wnd.title_align,
        focusable = wnd.input,
        relative = 'editor',
        border = 'rounded',
        style = 'minimal',
    }
    return wnd_opts
end

local function reopen_wnd(wnd)
    local wnd_opts = get_wnd_opts(wnd)
    local no_wnd = wnd.wnd_id == nil
    if no_wnd then
        local wnd_id = vim.api.nvim_open_win(wnd.buf_id, false, wnd_opts)
        if wnd_id == 0 then
            error('could not open a window')
        end
        wnd.wnd_id = wnd_id
    else
        vim.api.nvim_win_set_config(wnd.wnd_id, wnd_opts)
    end
end

local function close_wnd(wnd)
    local no_wnd = wnd.wnd_id == nil
    if not no_wnd then
        vim.api.nvim_win_close(wnd.wnd_id, false)
        wnd.wnd_id = nil
    end
end

function M.init(opts)
    M.no_render = opts.no_render or false
    M.wnds = {}
    vim.api.nvim_create_autocmd({ 'VimResized' }, {
        callback = function(_) M.update_all() end
    })
    on_screen_update()
end

function M.update_all()
    for _, wnd in pairs(M.wnds) do
        -- recalculate pos, size
        update_wnd(wnd)
        M.render(wnd)
    end
end

---create a new hidden window
---@class TaggedVec xy vector, with absolute (50u) & relative values (50%)
---@field x string x component
---@field y string y component
---
---@class NewOpts opts for wnd.new
---@field id string unique window id handle
---@field pos TaggedVec window position in abs/rel units
---@field size TaggedVec window size in abs/rel units
---@field anchor string? window corner anchor: 'NW' (default), 'NE', 'SW', 'SE'
---@field title string? window title, displayed on top border
---@field title_align string? align: 'left' (default), 'center', 'right'
---@field render function? buffer rendering function - render(wnd.body)
---@field input boolean? can the window accept user input
---
---@class Wnd wnd descriptor object
---@field id string unique window id handle
---@field pos TaggedVec window position in abs/rel units
---@field size TaggedVec window size in abs/rel units
---@field anchor string window corner anchor: 'NW' (default), 'NE', 'SW', 'SE'
---@field title string window title, displayed on top border
---@field title_align string align: 'left' (default), 'center', 'right'
---@field render function? rendering function - render(wnd.body), called int.
---@field body any body supplied to render function
---@field show boolean is window shown
---@field input boolean can the window accept user input
---@field wnd_id number? window id, nil when hidden
---@field buf_id number persistent buffer id
---
---@param opts NewOpts
---@return Wnd
function M.new(opts)
    local id = opts.id;
    if id == nil then
        error('window id is nil')
    end
    if M.wnds[id] == nil then
        local buf_id = vim.api.nvim_create_buf(true, true)
        if buf_id == 0 then
            error('could not create a buffer')
        end
        local render = opts.render
        if M.no_render then
            render = nil
        end
        local wnd = {
            id = id,
            pos = parse_vec(opts.pos),
            size = parse_vec(opts.size),
            anchor = opts.anchor or 'NW',
            title = opts.title or 'no-title',
            title_align = opts.title_align or 'left',
            render = render,
            body = {},
            show = false,
            input = opts.input or true,
            wnd_id = nil,
            buf_id = buf_id,
        }
        return wnd
    end
    error('window by this id already exists')
end

function M.on_key(wnd, key, act)
    vim.keymap.set('n', key, act, { buffer = wnd.buf_id, })
end

function M.move(wnd, pos)
    wnd.pos = parse_vec(pos)
    M.reconf(wnd)
end

function M.resize(wnd, size)
    wnd.size = parse_vec(size)
    M.reconf(wnd)
end

function M.rename(wnd, title)
    wnd.title = title
    M.reconf(wnd)
end

function M.render(wnd)
    local body = wnd.body
    local no_int = wnd.int == nil
    local no_render = wnd.render == nil
    if no_int then
        update_wnd(wnd)
    end
    if not no_render then
        u.defer(function() wnd.render(wnd, body) end)
    end
end

function M.reconf(wnd)
    if wnd.show then
        reopen_wnd(wnd)
    end
end

function M.show(wnd)
    if not wnd.show then
        reopen_wnd(wnd)
        wnd.show = true
    end
end

function M.hide(wnd)
    if wnd.show then
        close_wnd(wnd)
        wnd.show = false
    end
end

function M.focus(wnd)
    vim.api.nvim_set_current_win(wnd.wnd_id)
end

function M.bind(wnd, body)
    wnd.body = body
    M.render(wnd)
end

function M.del(wnd)
    close_wnd(wnd)
    vim.api.nvim_buf_delete(wnd.buf_id, { unload = true })
end

return M
