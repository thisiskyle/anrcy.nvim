

local M = {}



---@param bufn number
---
local function enableModifiable(bufn)
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufn })
end

---@param bufn number
---
local function disableModifiable(bufn)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufn })
    vim.api.nvim_set_option_value("modified", false, { buf = bufn })
end


---@param bufn number
---
local function apply_basic_buf_settings(bufn)
    vim.api.nvim_set_option_value("fileformat", "unix", { buf = bufn })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufn })
    vim.api.nvim_set_option_value("filetype", "text", { buf = bufn })
    vim.api.nvim_set_option_value("swapfile", false, { buf = bufn })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufn })
    disableModifiable(bufn)
end



--- starts at given id and increments until it finds 
--- an available base + id for a buffer
---@param base string
---@param id number
---
function M.find_buf_name(base, id)
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

    return M.find_buf_name(base, id + 1)
end


---@param bufn number
---@param data string[]
---
function M.write(bufn, data)
    if(not data) then
        return
    end
    enableModifiable(bufn)
    vim.api.nvim_buf_set_lines(bufn, 0, -1, false, data)
    disableModifiable(bufn)
end


---@param bufn number
---@param data string[]
---
function M.insert_at_top(bufn, data)
    vim.api.nvim_buf_set_lines(bufn, 0, 0, false, data)
end


---@param name string
---@param singleton boolean
---
function M.create_buffer(name, singleton)
    local _bufn = vim.api.nvim_create_buf(true, false)
    local _name = name:gsub(" ", "_")

    if(singleton) then
        vim.api.nvim_buf_set_name(_bufn, _name)
    else
        vim.api.nvim_buf_set_name(_bufn, M.find_buf_name(_name, 1))
    end

    apply_basic_buf_settings(_bufn)

    return _bufn
end


return M
