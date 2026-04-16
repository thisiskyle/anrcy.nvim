
---@type anrcy.Config_Opts
local default_opts = {
    global_after = nil,
    animation = "cat",
    animations = {
        cat = {
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
    }
}


local M = {
    opts = default_opts
}

--- Merge custom config with default config
---@param opts anrcy.Config_Opts
---
function M.setup(opts)
    local merged = vim.tbl_deep_extend("force", M.opts, opts or {})

    for k,v in pairs(merged) do
        M.opts[k] = v
    end
end

return M
