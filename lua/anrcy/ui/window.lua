local M = {}



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


function M.create_window(bufn, opts)
    return vim.api.nvim_open_win(bufn, true, opts)
end


return M
