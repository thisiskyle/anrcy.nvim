---@class anrcy.RequestData
---@field urlencode? string[]
---@field raw? string[]
---@field lua? table
---@field standard? string[]
---@field binary? string[]
---@field form? string[]

---@class anrcy.HttpRequest table with the data needed to make an http request
---@field type string
---@field url string
---@field headers? string[]
---@field additional_args? string[]
---@field data? anrcy.RequestData



---@class anrcy.Curl
local M = {}

local request_types = {
    get = { "-X", "GET", "--get" },
    post = { "-X", "POST" },
}


local function insert_with_prefix(cmd_table, data, prefix)
    if(type(data) == "string") then
        cmd_table[#cmd_table + 1] = prefix
        cmd_table[#cmd_table + 1] = data
    end
end


--- Build the curl command string from a anrcy.HttpRequest
---@param request anrcy.HttpRequest
---@return string[]
---
function M.build(request)

    local curl_command = {}
    local request_type = string.lower(request.type)

    curl_command[#curl_command + 1] = "curl"
    curl_command[#curl_command + 1] = "-s"

    if(request.additional_args) then
        for _,v in ipairs(request.additional_args) do
            curl_command[#curl_command + 1] = v
        end
    end

    for _,v in ipairs(request_types[request_type]) do
        curl_command[#curl_command + 1] = v
    end

    if(request.headers ~= nil) then
        for _,v in ipairs(request.headers) do
            insert_with_prefix(curl_command, v, "--header")
        end
    end


    if(request.data) then

        if(request.data.urlencode) then
            for _,v in ipairs(request.data.urlencode) do
                insert_with_prefix(curl_command, v, "--data-urlencode")
            end
        end

        if(request.data.raw) then
            for _,v in ipairs(request.data.raw) do
                insert_with_prefix(curl_command, v, "--data-raw")
            end
        end

        if(request.data.lua) then
            if(_G.type(request.data.lua) == "table") then
                insert_with_prefix(curl_command, vim.json.encode(request.data.lua), "--data")
            end
        end

        if(request.data.standard) then
            for _,v in ipairs(request.data.standard) do
                insert_with_prefix(curl_command, v, "--data")
            end
        end

        if(request.data.binary) then
            for _,v in ipairs(request.data.binary) do
                insert_with_prefix(curl_command, v, "--data-binary")
            end
        end

        if(request.data.form) then
            for _,v in ipairs(request.data.form) do
                insert_with_prefix(curl_command, v, "--form")
            end
        end

    end

    curl_command[#curl_command + 1] = request.url
    return curl_command

end

return M
