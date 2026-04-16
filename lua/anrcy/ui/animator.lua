


---@class anrcy.Animator
local M = {}

---@param animation? anrcy.Animation
---@return string -- the frame to be displayed
---
function M.get_frame(animation)
    if(not animation) then
        return ""
    end
    local frame_index = math.floor((vim.uv.hrtime() / 1e6) / animation.delta_time_ms) % #animation.frames + 1
    return animation.frames[frame_index]
end


return M
