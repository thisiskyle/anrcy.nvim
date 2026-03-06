local M = {}


function M.insert_template()
    local template = [[{
    name = "",
    type = "",
    url = "",
    headers = { },
    additional_args = { },
    show_cmd = false,
    data = {
        standard = {},
    },
    after = function() end,
    test = function() end,
}
]]

    vim.fn.setreg('0', template)
    vim.api.nvim_feedkeys('"0pjjf"', 'n', true)

end


function M.get_curl_string(arr)
    local cmd = ""
    local quoteFlag = false
    for _, v in ipairs(arr) do
        local d = v

        if(quoteFlag) then
            d = d:gsub('[\\$"]', "\\%0")
            d = d:gsub("%s+", " ")
            d = '"' .. d .. '"'
            quoteFlag = false
        else
            local di,_ = string.find(d, "--data")
            local hi,_ = string.find(d, "--header")
            if(di or hi) then
                quoteFlag = true
            end
        end

        cmd = cmd .. ' ' .. d

    end
    return cmd:gsub("^%s+","")
end






--- Get the currently selected text from the buffer
---
function M.get_visual_selection()
    local s_start = vim.fn.getpos("'<")
    local s_end = vim.fn.getpos("'>")
    local n_lines = math.abs(s_end[2] - s_start[2]) + 1
    local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)

    if(next(lines) == nil) then
        require("anrcy.ui").notify("Nothing selected", "info")
        return ""
    end


    lines[1] = string.sub(lines[1], s_start[3], -1)
    if n_lines == 1 then
        lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
    else
        lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
    end
    return table.concat(lines, '\n')
end


--- Remove line endings from the provided data
--- @return any
---
function M.remove_line_endings(data)
    local output = {}
    for _,v in ipairs(data) do
        local s = v:gsub('\r\n?', ''):gsub('\n', '')
        table.insert(output, s)
    end
    return output
end

--- This function is for parsing the output from curl.
--- In some cases, curl will return more than just the request response.
--- In these cases we want to be able to split the extra curl information
--- from the actual response so we may run operations on them seperately
---
--- todo: For now, this only works when the response is json, because thats all I use it for
---@param data any
---@return table
---
function M.parse_output(data)

    local split_idx = 0
    local split_data = { curl_header = {}, payload = {} }

    for i,v in ipairs(data) do
        if(v:match("^[%[%{]") ~= nil) then
            split_idx = i
        end
    end

    -- there is no json found
    if(split_idx == 0) then
        split_data.payload = data
        return split_data
    end

    for i = 1, split_idx - 1, 1 do
        table.insert(split_data.curl_header, data[i])
    end

    for i = split_idx, #data, 1 do
        table.insert(split_data.payload, data[i])
    end

    return split_data
end


--- todo: unused
--- this isn't 100% accurate, but should work 
--- for out purposes
---
---@return boolean
---
function M.is_array(t)
    if(t[1]) then
        return true
    end
    return false
end

--- todo: unused
--- Because we are using a visual selection as our input
--- we are going to try and be flexible here. By default we wrap the 
--- selected text in an array, but incase the user has already selected
--- an array, we are going to dig into the table and try to correctly
--- extract the inner array
---
---@return table
---
function M.validate(t)
    if(M.is_array(t) == true) then
        if(M.is_array(t[1]) == true) then
            return t[1]
        else
            return t
        end
    else
        return { t }
    end
end

--- Get the visual selection block and inject it into a temp file
--- this temp file will be loaded as lua with dofile
---@return Job[]?
---
function M.get_visual_selection_as_lua()
    local selected = M.get_visual_selection()
    if(selected == nil or selected == "") then
        return nil
    end
    local path = vim.fn.stdpath("cache") .. "/tmp.lua"
    local file = io.open(path, "w")

    if(file) then
        file:write("return {\n" .. selected .. "\n}")
        file:close()
    end

    local data = dofile(path)

    return data
end

return M
