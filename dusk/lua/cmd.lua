local M = {}

function M.exec_vim(cmd)
    local result = vim.api.nvim_exec2(cmd, { output = true, })
    if result.error == nil then
        return result.output
    else
        return result.error
    end
end

function M.exec_sys(cmd)
    return M.exec_vim('! ' .. cmd)
end

return M
