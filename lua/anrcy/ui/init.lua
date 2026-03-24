local utils = require("anrcy.utils")


local M = {}
local history_buf_name = "anrcy_history"



--- Formats the test results into a string[] for buffer insertion
---@param results table
---@return string[]
---
local function format_test_results(results)
    local content = {}
    for i,v in ipairs(results) do
        local result = (v.result) and "pass" or "fail"
        local name = (v.name and v.name ~= "") and v.name or ("Test ".. i)
        content[#content + 1] = "[" .. result .. "] " .. name
    end
    return content
end

--- Calculate the values to center and size a floating window
---
local function calc_float_window()
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


local function apply_basic_buf_settings(bufn)
    vim.api.nvim_set_option_value("fileformat", "unix", { buf = bufn })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufn })
    vim.api.nvim_set_option_value("filetype", "text", { buf = bufn })
    vim.api.nvim_set_option_value("swapfile", false, { buf = bufn })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufn })
end


--- starts at given id and finds and increments until it finds 
--- an available base + id for a buffer
---@param base string
---@param id number
---
local function find_buf_name(base, id)
    local name = base .. id

    if(vim.fn.bufexists(name) == 0) then
        return name
    else
        if(vim.fn.bufloaded(name) == 0) then
            local bufn = vim.fn.bufnr(name)
            vim.api.nvim_buf_delete(bufn, { force = true })
            return name
        end
    end

    return find_buf_name(base, id + 1)
end


--- Writes data to a buffer
---@param bufn number
---@param data string[]
---
local function write(bufn, data)
    if(not data) then
        return
    end
    vim.api.nvim_buf_set_lines(bufn, 0, -1, false, data)
end


--- Insert at top of buffer
---@param bufn number
---@param data string[]
---
local function insert_at_top(bufn, data)
    vim.api.nvim_buf_set_lines(bufn, 0, 0, false, data)
end



local function create_window(bufn, opts)

    return vim.api.nvim_open_win(bufn, true, opts)
end



local function create_buffer(name, singleton)
    local _bufn = vim.api.nvim_create_buf(true, false)
    local _name = name:gsub(" ", "_")

    if(singleton) then
        vim.api.nvim_buf_set_name(_bufn, _name)
    else
        vim.api.nvim_buf_set_name(_bufn, find_buf_name(_name, 1))
    end

    apply_basic_buf_settings(_bufn)

    return _bufn
end


local function create_and_open(opts)
    local bufn = create_buffer(opts.name, opts.singleton)
    write(bufn, opts.payload)
    create_window(bufn, opts.window)
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


--- Displays each Response in a new buffer
--- and runs the after() function if there is one
---@param responses anrcy.Response[]
---
function M.show(responses)
    for _,r in pairs(responses) do

        if(r.error) then
            create_and_open({
                name = r.name .. "_error",
                singleton = false,
                payload = r.error,
                window = { split = "right" }
            })
        else

            local bufn = create_and_open({
                name = r.name,
                singleton = false,
                payload = r.data.payload,
                window = { split = "right" }
            })

            write(bufn, r.data.payload)

            if(r.after) then
                r.after(r.data)
            end

            local next = next

            if(next(r.data.curl_header)) then
                insert_at_top(bufn, { " ", " " })
                insert_at_top(bufn, r.data.curl_header)
            end

            if(r.show_curl) then
                local cmd = utils.get_curl_string(r.curl_cmd)
                insert_at_top(bufn, { " ", " " })
                insert_at_top(bufn, { cmd })
            end

            if(r.test_results) then
                insert_at_top(bufn, { " ", " " })
                insert_at_top(bufn, format_test_results(r.test_results))
            end

            vim.cmd(":norm gg")
        end

    end
end

--- 
function M.show_history(history)

    local payload = {}

    local float = calc_float_window()

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

    for _,v in ipairs(history) do
        local str = ""
        for _,j in ipairs(v) do
            str = str .. "(" .. j.name .. ")" .. " "
        end
        payload[#payload + 1] = str
    end

    local bufn = -1

    if(vim.fn.bufexists(history_buf_name) > 0) then
        M.close_history()
    end

    bufn = create_and_open({
        name = history_buf_name,
        singleton = true,
        payload = payload,
        window = window_opts
    })

    vim.api.nvim_set_option_value("modifiable", false, { buf = bufn })
    return bufn
end


function M.close_history()
    local bufn = vim.fn.bufnr(history_buf_name)
    vim.api.nvim_buf_delete(bufn, { force = true })
end


--- Displays a notification
---@param message string
---@param level string
---
function M.notify(message, level, opts)
    local default = { title = "", icon = "[Anrcy]" }
    local o = vim.tbl_deep_extend("force", default, opts or {})
    vim.notify(message, level, o)
end

--- Displays a notification of the current job progress
---@param target number
---@param completed number
---
function M.show_progress(target, completed, animation)

    local animator = require("anrcy.ui.animator")
    local spinner = animator.get_frame(animator.animations[animation])
    local message =  completed .. "/" .. target .. "  " .. spinner

    if(completed == target) then
        message = "Complete!"
    end

    M.notify(message, "info", { id = "anrcy_progress", title = "Progress" })

end

--- Creates a dummy notification that displays all the animations
--- this probably only works because I am using snacks notifier
---@param count number
---
function M.animation_test(count)
    if(count <= 0) then
        return
    end

    ---@type anrcy.Animator
    local animator = require("anrcy.ui.animator")
    local message = ""

    for k,v in pairs(animator.animations) do
        message = message .. k .. ": " .. animator.get_frame(v) .. "\n"
    end

    M.notify(message, "info", {
        id = "anrcy_animate",
        title = "Testing Animations"
    })

    count = count - 1
    vim.defer_fn(function() M.animation_test(count) end, 50)
end


--- Creates a dummy notification that displays test progress
---@param count number
---
function M.progress_test(count)
    if(count <= 0) then
        return
    end
    local t = math.floor(500 / 100) - 1
    local c = math.floor((500 - count) / 100)
    M.show_progress(t, c, "default")
    count = count - 1
    vim.defer_fn(function() M.progress_test(count) end, 50)
end

return M
