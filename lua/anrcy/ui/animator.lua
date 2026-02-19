---@class anrcy.Animation
---@field delta_time_ms number
---@field frames string[]

---@class anrcy.Animator
---@field animations anrcy.Animation[]
---@field get_frame fun(animation: anrcy.Animation): string
---
local M = {}

M.animations = {
    ---@type anrcy.Animation
    none = {
        delta_time_ms = 600,
        frames = { "" }
    },

    ---@type anrcy.Animation
    default = {
        delta_time_ms = 600,
        frames = {
            "ᓚᘏᗢ zzz",
            "ᓚᘏᗢ Zzz",
            "ᓚᘏᗢ ZZz",
            "ᓚᘏᗢ ZZZ",
            "ᓚᘏᗢ zZZ",
            "ᓚᘏᗢ zzZ",
        }
    },

    catch = {
        delta_time_ms = 200,
        frames = {
            "(o    )=",
            "==(o  )=",
            "(   o )=",
            "=(   o)=",
            "=(    o)",
            "=(  o)==",
            "=( o   )",
            "=(o   )=",
        }
    },
}


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
