local M = {}

local context_source = "anrcy"
local qf_title = "Anrcy Responses"


---@param buffers number[]
---
function M.create(buffers)
    local qf_items = {}

    for _,v in ipairs(buffers) do
        qf_items[#qf_items + 1] = {
            bufnr = v,
            lnum = 1,
            col = 1,
            user_data = {
                anrcy = true
            }
        }
    end

    vim.fn.setqflist({}, " ", {
        title = qf_title,
        items = qf_items,
        context = { source = context_source }
    })
end




function M.use_custom_quickfix_swapping()
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("anrcy", { clear = true }),
        pattern = "qf",
        callback = function(args)
            local temp = vim.fn.getqflist({ idx = 0, items = 0, context = 1 })
            if(temp.context and temp.context.source == context_source) then
                vim.keymap.set("n", "<CR>", function()
                    local win = vim.fn.win_getid(vim.fn.winnr("#"))
                    if(win) then
                        local qf = vim.fn.getqflist({ idx = 0, items = 1 })
                        local line = vim.fn.line(".")
                        local item = qf.items[line]
                        if(item and item.user_data and item.user_data.anrcy) then
                            vim.api.nvim_win_set_buf(win, item.bufnr)
                            vim.api.nvim_set_current_win(win)
                            return
                        end
                    end
                    -- fallback
                    local tqf = vim.fn.getqflist({ idx = 0, items = 0 })
                    vim.cmd(("buffer %d"):format(tqf.items[tqf.idx].bufnr))
                end, { buffer = args.buf })
            end
        end,
    })
end


return M
