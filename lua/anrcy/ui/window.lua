local M = {}


local tag = "anrcy_response_tag"


--- Calculate the values to center and size a floating window
---
function M.calc_float_window()
    local editor = vim.api.nvim_list_uis()[1]

    local w = math.floor(editor.width * 0.5)
    local h = math.floor(editor.height * 0.5)

    return {
        w = w,
        h = h,
        x = ((editor.width - w) / 2),
        y = ((editor.height - h) / 2)
    }
end


function M.setWindow(winid, bufn)
    vim.api.nvim_win_set_buf(winid, bufn)
end


function M.create(bufn, opts)
    local win = vim.api.nvim_open_win(bufn, true, opts)
    vim.api.nvim_win_set_var(win, tag, true)
    return win
end


function M.focus(winid)
    vim.api.nvim_set_current_win(winid)
end


function M.findResponseWindow()
    for _,win in ipairs(vim.api.nvim_list_wins()) do
        local ok,value = pcall(vim.api.nvim_win_get_var, win, tag)
        if(ok and value) then
            return win
        end
    end
    return nil
end


return M
