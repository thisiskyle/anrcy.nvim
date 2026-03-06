local utils = require("anrcy.utils")


local M = {}


--- Formats the test results into a string[] for buffer insertion
---@param results table
---@return string[]
---
local function format_test_results(results)
    local content = {}
    for _,v in pairs(results) do
        local result = (v.result) and "pass" or "fail"
        table.insert(content, "[" .. result .. "] " .. v.name)
    end
    return content
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


local function apply_buffer_settings()
    vim.cmd(":set fileformat=unix")
    vim.opt_local.buftype = "nofile"
    vim.opt_local.filetype = "text"
    vim.opt_local.swapfile = false
end


--- Creates a buffer
---@param name string
---@param vertical_split boolean
---
local function create(name, vertical_split, singleton)
    local n = name:gsub(" ", "_")

    if(vertical_split) then
        vim.cmd(":vnew")
        vim.cmd(":wincmd L")
    else
        vim.cmd(":new")
    end

    if(singleton) then
        vim.cmd(":file " .. n)
    else
        vim.cmd(":file " .. find_buf_name(n .. "_", 1))
    end

    apply_buffer_settings()
    return vim.api.nvim_get_current_buf()

end


--- Displays each command string in a buffer
---@param cmds string[]
---
function M.show_commands(cmds)
    local bufn = create("curl commands", true, false)
    write(bufn, utils.remove_line_endings(cmds))
end


--- Displays each Response in a new buffer
--- and runs the after() function if there is one
---@param responses anrcy.Response[]
---
function M.show(responses)
    local i = 0;

    for _,r in pairs(responses) do

        local vertical_split = (i == 0)

        if(r.error) then
            local bufn = create(r.name .. "_error", vertical_split, false)
            write(bufn, r.error)
        else

            local bufn = create(r.name, vertical_split, false)

            write(bufn, r.data.payload)
            if(r.after) then
                r.after(r.data)
            end

            local next = next

            if(next(r.data.curl_header)) then
                insert_at_top(bufn, { " ", " " })
                insert_at_top(bufn, r.data.curl_header)
            end

            if(r.show_cmd) then
                local cmd = utils.get_curl_string(r.cmd)
                insert_at_top(bufn, { " ", " " })
                insert_at_top(bufn, { cmd })
            end

            if(r.test_results) then
                insert_at_top(bufn, { " ", " " })
                insert_at_top(bufn, format_test_results(r.test_results))
            end

            vim.cmd(":norm gg")
        end

        i = i + 1
    end
end

--- 
--- 
--- 
function M.show_history(history)

    if(next(history) == nil) then
        M.notify("Anrcy history is empty", "info")
        return
    end

    local name = "anrcy_history"
    local payload = {}

    for _,v in ipairs(history) do
        local str = ""
        for _,j in ipairs(v) do
            str = str .. j.name .. " "
        end
        table.insert(payload, str);
    end

    if(vim.fn.bufexists(name) == 0) then
        local bufn = create(name, false, true)
        write(bufn, payload)
    else
        local bufn = vim.fn.bufnr(name)

        if(not vim.api.nvim_buf_is_loaded(bufn) or #vim.fn.win_findbuf(bufn) == 0) then
            vim.cmd(":new")
            vim.cmd(":b " .. bufn)
            apply_buffer_settings()
        end

        write(bufn, payload)
    end

    vim.cmd(":norm gg")
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
