local M = {}


function M.insert_template()
    local template = [[{
    name = "",
    type = "",
    url = "",
    headers = { },
    additional_args = { },
    show_curl = false,
    data = { },
    after = function() end,
    test = function() end,
},
]]

    vim.fn.setreg('0', template)
    vim.api.nvim_feedkeys('"0pjjf"', 'n', true)

end


---@param arr string[]
---
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

    local mode = vim.api.nvim_get_mode().mode
    local start_pos
    local end_pos
    local region_type

    if mode:match("[vV\22]") then
        start_pos = vim.fn.getpos("v")
        end_pos = vim.fn.getpos(".")
        region_type = vim.fn.mode()
    else
        start_pos = vim.fn.getpos("'<")
        end_pos = vim.fn.getpos("'>")
        region_type = vim.fn.visualmode()
    end

    local lines = vim.fn.getregion(start_pos, end_pos, { type = region_type })
    return table.concat(lines, '\n')
end


--- Remove line endings from the provided data
--- @return any
---
function M.remove_line_endings(data)
    local output = {}
    for _,v in ipairs(data) do
        local s = v:gsub('\r\n?', ''):gsub('\n', '')
        output[#output + 1] = s
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
        split_data.curl_header[#split_data.curl_header + 1] = data[i]
    end

    for i = split_idx, #data, 1 do
        split_data.payload[#split_data.payload + 1] = data[i]
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
---
---@return anrcy.Job[]
---
function M.get_visual_selection_as_lua()
    local selected = M.get_visual_selection()
    if(selected == nil or selected == "") then
        return {}
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


--- Formats the test results into a string[] for buffer insertion
---
---@param results table
---@return string[]
---
function M.format_test_results(results)
    local content = {}
    for i,v in ipairs(results) do
        local result = (v.result) and "pass" or "fail"
        local name = (v.name and v.name ~= "") and v.name or ("Test ".. i)
        content[#content + 1] = "[" .. result .. "] " .. name
    end
    return content
end


return M
