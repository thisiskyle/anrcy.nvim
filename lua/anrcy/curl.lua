---@class anrcy.RequestData
---@field urlencode? string[]
---@field raw? string[]
---@field lua? table
---@field standard? string[]
---@field binary? string[]
---@field form? string[]

---@class anrcy.HttpRequest table with the data needed to make an http request
---@field method string
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


--- Insert the provided prefix and the command into the provided table
---@param cmd_table table table to insert into
---@param data table array of data arguments to add to the curl command
---@param prefix string prefix for each of the data arguments
---
local function insert_with_prefix(cmd_table, data, prefix)
    if(data == nil) then
        return
    end

    for _,v in ipairs(data) do
        if(type(v) == "string") then
            cmd_table[#cmd_table + 1] = prefix
            cmd_table[#cmd_table + 1] = v
        end
    end
end


--- Build the curl command string from a anrcy.HttpRequest
---@param request anrcy.HttpRequest
---@return string[]
---
function M.build(request)

    local curl_command = {}
    local request_type = string.lower(request.method)

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


    insert_with_prefix(curl_command, request.headers, "--header")


    if(request.data) then


        insert_with_prefix(curl_command, request.data.urlencode, "--data-urlencode")
        insert_with_prefix(curl_command, request.data.raw, "--data-raw")
        insert_with_prefix(curl_command, request.data.standard, "--data")
        insert_with_prefix(curl_command, request.data.binary, "--data-binary")
        insert_with_prefix(curl_command, request.data.form, "--form")

        if(request.data.lua) then
            if(_G.type(request.data.lua) == "table") then
                insert_with_prefix(curl_command, { vim.json.encode(request.data.lua) }, "--data")
            end
        end

    end

    curl_command[#curl_command + 1] = request.url
    return curl_command

end

return M
