local utils = require("anrcy.utils")
local config = require("anrcy.config")

local animator = require("anrcy.ui.animator")
local buffer = require("anrcy.ui.buffer")
local window = require("anrcy.ui.window")


---@class anrcy.Ui
local M = {}

local history_buf_name = "anrcy_history"


---@param opts anrcy.Display_Opts
---
local function create_and_open(opts)
    local bufn = buffer.create_buffer(opts.name, opts.singleton)
    buffer.write(bufn, opts.payload)
    window.create_window(bufn, opts.window)
    return bufn
end



---@param cmds string[]
---
function M.show_commands(cmds)
    create_and_open({
        name = "curl commands",
        singleton = false,
        payload = utils.remove_line_endings(cmds),
        window = { split = "right" }
    })
end


---@param responses anrcy.Response[]
---
function M.show_response(responses)
    for _,r in pairs(responses) do

        if(#r.stderr > 0) then

            create_and_open({
                name = r.name .. "_error",
                singleton = false,
                payload = r.stderr,
                window = { split = "right" }
            })

        else

            local bufn = create_and_open({
                name = r.name,
                singleton = false,
                payload = r.data.payload,
                window = { split = "right" }
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

            vim.cmd(":norm gg")
        end

    end
end


---@param history string[]
---
function M.show_history(history)

    local float = window.calc_float_window()

    local window_opts = {
        relative = 'editor',
        row = float.y,
        col = float.x,
        width = float.w,
        height = float.h,
        border = "single",
        title = "Anrcy History",
        title_pos = "center"
    }

    if(vim.fn.bufexists(history_buf_name) > 0) then
        M.close_history()
    end

    local bufn = create_and_open({
        name = history_buf_name,
        singleton = true,
        payload = history,
        window = window_opts
    })

    vim.api.nvim_set_option_value("modifiable", false, { buf = bufn })
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

    if(config.opts.animation ~= nil and config.opts.animation ~= "") then
        spinner = animator.get_frame(config.opts.animations[config.opts.animation])
    end

    local message =  completed .. "/" .. target .. "  " .. spinner

    if(completed == target) then
        message = "Complete!"
    end

    M.notify(message, "info", { id = "anrcy_progress", title = "Progress" })

end



return M
