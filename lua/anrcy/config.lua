
---@class anrcy.Config
---@field global_after? fun(data: string[])
---@field animation? string

local M = {}

---@type anrcy.Config
M.defaults = {
    animation = "default"
}

---@type anrcy.Config
M.options = M.defaults

--- Merge custom config with default config
---@param opts anrcy.Config -- custom config
---
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
