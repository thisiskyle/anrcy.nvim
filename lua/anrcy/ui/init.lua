local utils = require("anrcy.utils")
local config = require("anrcy.config")

local animator = require("anrcy.ui.animator")
local buffer = require("anrcy.ui.buffer")
local window = require("anrcy.ui.window")
local quickfix = require("anrcy.ui.quickfix")


---@class anrcy.Ui
local M = {}

local history_buf_name = "anrcy_history"


---@param opts anrcy.Buffer_Opts
---@return number
---
local function create_buffer(opts)
    local bufn = buffer.create_buffer(opts.name, opts.singleton)
    buffer.write(bufn, opts.payload)
    return bufn
end

---@param buffers number[]
---
local function open_quickfix_layout(buffers)
    quickfix.create(buffers)
    local win = window.create(0, { split = "right"})
    vim.cmd("cfirst")
    if(#buffers > 1) then
        vim.cmd("copen")
    end
    window.focus(win)
end


---@param cmds string[]
---
function M.show_commands(cmds)
    local bufn = create_buffer({
        name = "curl commands",
        singleton = false,
        payload = utils.remove_line_endings(cmds),
    })
    window.create(bufn, { split = "right" })
end


---@param responses anrcy.Response[]
---
function M.show_response(responses)
    local buffers = {}

    for _,r in pairs(responses) do

        if(#r.stderr > 0) then

            buffers[#buffers + 1] = create_buffer({
                name = r.name .. "_error",
                singleton = false,
                payload = r.stderr
            })

        else

            local bufn = create_buffer({
                name = r.name,
                singleton = false,
                payload = r.data.payload
            })

            buffer.write(bufn, r.data.payload)

            local next = next

            if(next(r.data.curl_header)) then
                buffer.insert_at_top(bufn, { " ", " " })
                buffer.insert_at_top(bufn, r.data.curl_header)
            end

            if(r.show_curl) then
                local cmd = utils.get_curl_string(r.curl_cmd)
                buffer.insert_at_top(bufn, { " ", " " })
                buffer.insert_at_top(bufn, { cmd })
            end

            if(r.test_results) then
                buffer.insert_at_top(bufn, { " ", " " })
                buffer.insert_at_top(bufn, utils.format_test_results(r.test_results))
            end

            buffers[#buffers + 1] = bufn
        end

    end

    open_quickfix_layout(buffers)
end


---@param history string[]
---
function M.show_history(history)

    local float = window.calc_float_window()


    if(vim.fn.bufexists(history_buf_name) > 0) then
        M.close_history()
    end

    local bufn = create_buffer({
        name = history_buf_name,
        singleton = true,
        payload = history,
    })

    window.create(bufn, {
        relative = 'editor',
        row = float.y,
        col = float.x,
        width = float.w,
        height = float.h,
        border = "single",
        title = "Anrcy History",
        title_pos = "center"
    })

    vim.api.nvim_set_option_value("modifiable", false, { buf = bufn })
    vim.wo.cursorline = true

    return bufn
end


function M.close_history()
    local bufn = vim.fn.bufnr(history_buf_name)
    vim.api.nvim_buf_delete(bufn, { force = true })
end


---@param message string
---@param level string
---
function M.notify(message, level, opts)
    local default = { title = "", icon = "[Anrcy]" }
    local o = vim.tbl_deep_extend("force", default, opts or {})
    vim.notify(message, level, o)
end


---@param target number
---@param completed number
---
function M.show_progress(target, completed)

    local spinner = ""

    if(config.opts.animate) then
        spinner = animator.get_frame()
    end

    local message =  completed .. "/" .. target .. "  " .. spinner

    if(completed == target) then
        message = "Complete!"
    end

    M.notify(message, "info", { id = "anrcy_progress", title = "Progress" })

end


return M
