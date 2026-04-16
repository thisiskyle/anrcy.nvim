

local M = {}


local history = {}
local bookmark = nil



local function setup_keymaps(bufn)
    vim.keymap.set(
        'n',
        '<cr>',
        function()
            local lineNum = vim.api.nvim_win_get_cursor(0)[1]
            require("anrcy").process_jobs(M.get(lineNum))
            require("anrcy.ui").close_history()
        end,
        {
            buffer = bufn,
            desc = 'anrcy: run from history'
        }
    )

    vim.keymap.set(
        'n',
        'q',
        function()
            require("anrcy.ui").close_history()
        end,
        {
            buffer = bufn,
            desc = 'anrcy: close history'
        }
    )
end


function M.get_all()
    return history
end


function M.get_last()
    return history[1]
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


function M.show()

    local payload = {}

    for _,v in ipairs(history) do
        local str = ""

        for i,j in ipairs(v) do
            str = str .. j.name

            if(i ~= #v) then
                str = str .. ", "
            end
        end

        payload[#payload + 1] = str
    end

    local bufn = require("anrcy.ui").show_history(payload)
    setup_keymaps(bufn)
end



return M
