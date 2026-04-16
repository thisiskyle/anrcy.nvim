
local config = require("anrcy.config")
local utils = require("anrcy.utils")
local ui = require("anrcy.ui")
local curl = require("anrcy.curl")


---@type anrcy.Response[]
local active_responses = {}

---@type boolean[]
local completed_jobs = {}

---@type boolean[]
local inprogress_jobs = {}



local function clear_jobs()
    active_responses = {}
    completed_jobs = {}
    inprogress_jobs = {}
end


local function monitor_progress()
    local run = 0
    local done = 0

    for _,_ in pairs(inprogress_jobs) do
        run = run + 1
    end

    for _,_ in pairs(completed_jobs) do
        done = done + 1
    end

    ui.show_progress(run + done, done)

    if(run == 0) then
        clear_jobs()
        return
    end

    vim.defer_fn(monitor_progress, 60)
end


---@param j anrcy.Job
---@return string[] | string
---
local function job_to_curl(j)
    return j.command or curl.build({
        type = j.type,
        url = j.url,
        headers = j.headers,
        data = j.data,
        additional_args = j.additional_args,
    })
end


---@class anrcy.Job_Handler
local M = {}

--- Uses vim.fn.system and curl to make a syncronous http request
--- I am not sure if I will ever actually use this
---@param jobs anrcy.Job[]
---@return anrcy.Response[]
---
function M.sync(jobs)
    local responses = {}

    for _,j in ipairs(jobs) do

        ---@type string[] | string
        local cmd = job_to_curl(j)

        if(cmd == "" or cmd == nil) then
            ui.notify("Job command was empty", vim.log.levels.ERROR)
            break
        end

        local response = {
            name = j.name or "anrcy",
            show_curl = j.show_curl,
            curl_cmd = cmd,
            data = nil,
            error = nil,
            test_results = nil
        }

        local data = { vim.fn.system(cmd) }
        local norm = utils.remove_line_endings(data)
        response.data = utils.parse_output(norm)

        if(j.test) then
            response.test_results = j.test(response.data.payload)
        end

        responses[#responses + 1] = response

    end

    return responses
end


--- Uses vim.fn.jobstart and curl to make an asyncronous http request
---@param jobs anrcy.Job[]
---@param on_complete fun(data?: anrcy.Response[]) on_complete callback handler
---
function M.async(jobs, on_complete)

    for _,j in ipairs(jobs) do

        ---@type string[] | string
        local cmd = job_to_curl(j)

        if(cmd == "" or cmd == nil) then
            ui.notify("Job " .. j.name .. " command was empty", vim.log.levels.ERROR)
            goto continue
        end

        local response = {
            name = j.name or "anrcy",
            show_curl = j.show_curl,
            curl_cmd = cmd,
            stdout = {},
            stderr = {},
            data = nil,
            test_results = nil
        }

        local job_id = vim.fn.jobstart(
            cmd,
            {
                stdout_buffered = true,
                stderr_buffered = true,

                on_stdout = function(_, data, _)
                    if(next(data) ~= nil and data[1] ~= "") then
                        for _,v in pairs(data) do
                            response.stdout[#response.stdout + 1] = v
                        end
                    end

                end,

                on_stderr = function (_, data, _)
                    if(next(data) ~= nil and data[1] ~= "") then
                        for _,v in pairs(data) do
                            response.stderr[#response.stderr + 1] = v
                        end
                    end
                end,

                on_exit = function(id, _, _)

                    local norm = utils.remove_line_endings(response.stdout)
                    response.data = utils.parse_output(norm)

                    if(j.test) then
                        response.test_results = j.test(response.data.payload)
                    end

                    local modifiedPayload = nil

                    if(j.after) then
                        modifiedPayload = j.after(response.data.payload)
                    elseif(config.opts.global_after) then
                        modifiedPayload = config.opts.global_after(response.data.payload)
                    end

                    -- only overwrite the original payload if the modified payload is not nil
                    -- otherwise, just keep the original payload
                    if(modifiedPayload) then
                        response.data.payload = modifiedPayload
                    end

                    completed_jobs[id] = true
                    inprogress_jobs[id] = nil

                    if(next(inprogress_jobs) == nil) then
                        local responses = {}

                        for _,r in pairs(active_responses) do
                            table.insert(responses, r)
                        end

                        on_complete(responses)
                    end
                end,
            }
        )

        active_responses[job_id] = response
        inprogress_jobs[job_id] = true

        ::continue::
    end

    monitor_progress()
end


---@param jobs anrcy.Job[]
---
function M.show_commands_only(jobs)
    if(jobs == nil) then
        ui.notify("Job list is nil", vim.log.levels.ERROR)
        return
    end

    local lines = {}

    for _,j in ipairs(jobs) do

        local request = {
            type = j.type,
            url = j.url,
            headers = j.headers,
            data = j.data,
            additional_args = j.additional_args,
        }

        if(j.command) then
            lines[#lines + 1] = j.command
        else
            local cmd = curl.build(request)
            local cmdStr = require("anrcy.utils").get_curl_string(cmd)
            lines[#lines + 1] = cmdStr
        end
    end

    require("anrcy.ui").show_commands(lines)
end


M.clear_jobs = clear_jobs


return M
