
local animation = {
    delta_time_ms = 150,
    frames = {
        [[ (A)~~~~~~*]],
        [[ (A)~~~~~* ]],
        [[ (A)~~~~*  ]],
        [[ (A)~~~*   ]],
        [[ (A)~~*    ]],
        [[ (A)~*     ]],
        [[ (A)*      ]],
        [[ (A)       ]],
        [[( * )      ]],
        [[  *        ]],
        [[           ]],
        [[           ]],
    }
}



---@class anrcy.Animator
local M = {}

---@return string -- the frame to be displayed
---
function M.get_frame()
    local frame_index = math.floor((vim.uv.hrtime() / 1e6) / animation.delta_time_ms) % #animation.frames + 1
    return animation.frames[frame_index]
end


return M
