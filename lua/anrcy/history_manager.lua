

local M = {}


local history = {}
local bookmark = nil


function M.get_all()
    return history
end


function M.get_last()
    return history[#history]
end


function M.get(n)
    return history[n]
end


function M.archive(jobs)
    table.insert(history, 1, jobs)
end


function M.set_bookmark(jobs)
    bookmark = jobs
end


function M.get_bookmark()
    return bookmark
end


function M.setup_keymaps()
    vim.keymap.set(
        'n',
        '<cr>',
        function()
            local lineNum = vim.api.nvim_win_get_cursor(0)[1]
            require("anrcy").run_jobs(M.get(lineNum))
            require("anrcy.ui").show_history(history)
        end,
        {
            buffer = true,
            desc = 'anrcy: run from history'
        }
    )
end


return M
