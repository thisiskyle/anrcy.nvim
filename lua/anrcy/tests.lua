local config = require("anrcy.config")
local animator = require("anrcy.ui.animator")
local ui = require("anrcy.ui")


---@class anrcy.Tester
local M = {}

--- Creates a dummy notification that displays all the animations
--- this probably only works because I am using snacks notifier
---@param count number
---
function M.animation_test(count)
    if(count <= 0) then
        return
    end

    local message = ""

    for k,v in pairs(config.opts.animations) do
        message = message .. k .. ": " .. animator.get_frame(v) .. "\n"
    end

    ui.notify(message, "info", {
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
    ui.show_progress(t, c)
    count = count - 1
    vim.defer_fn(function() M.progress_test(count) end, 50)
end



return M
