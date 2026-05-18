
---@type anrcy.Config_Opts
local default_opts = {
    global_after = nil,
}


local M = {
    opts = default_opts
}

--- Merge custom config with default config
---@param opts anrcy.Config_Opts
---
function M.setup(opts)
    local merged = vim.tbl_deep_extend("force", default_opts, opts or {})
    for k,v in pairs(merged) do
        M.opts[k] = v
    end
end


function M.set_default()
    M.opts = default_opts
end


return M
