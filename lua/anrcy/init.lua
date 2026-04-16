require("anrcy.commands")

local config = require("anrcy.config")
local ui = require("anrcy.ui")

local M = {}


--- Setup the application with the provided options
---
function M.setup(opts)
    config.setup(opts)
end


--- Entry point function for running jobs from a provided list
---@param jobs? anrcy.Job[]
---
function M.process_jobs(jobs)
    if(jobs == nil) then
        ui.notify("Job list is empty", vim.log.levels.ERROR)
        return
    end

    require("anrcy.history_manager").archive(jobs)
    require("anrcy.job_handler").async(jobs, function(responses)
        ui.show_response(responses)
    end)
end


--- expects visually selected text to be a single, or multiple anrcy.Jobs
--- then runs those jobs and displays the output
---
function M.run_highlighted_jobs()
    local jobs = require("anrcy.utils").get_visual_selection_as_lua()
    M.process_jobs(jobs)
end


--- expects a url to be visually selected and uses that to create a basic GET job
--- then runs the job and displays the output
---
function M.get_highlighted_url()
    local _url = require("anrcy.utils").get_visual_selection()

    require("anrcy").process_jobs({
        {
            name = "anrcy_quick_get",
            type = "GET",
            url = _url
        }
    })
end


--- clear pending jobs
---
function M.clear_jobs()
    require("anrcy.job_handler").clear_jobs()
end


--- repeat the last run
---
function M.repeat_last()
    local jobs = require("anrcy.history_manager").get_last()
    M.process_jobs(jobs)
end


--- register a job list for quick access
---
function M.set_bookmark()
    local jobs = require("anrcy.utils").get_visual_selection_as_lua()
    require("anrcy.history_manager").set_bookmark(jobs)
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, 'nx', false)
    require("anrcy.ui").notify("Bookmark set!", vim.log.levels.INFO)
end


--- execute the registered job list
---
function M.execute_bookmark()
    local jobs = require("anrcy.history_manager").get_bookmark()
    M.process_jobs(jobs)
end


--- only display the curl command that is generated from the selected jobs
---
function M.show_curl()
    local jobs = require("anrcy.utils").get_visual_selection_as_lua()
    require("anrcy.job_handler").show_commands_only(jobs)
end


--- insert an anrcy.Job template at the cursor
---
function M.insert_template()
    require("anrcy.utils").insert_template()
end


--- display the run history
---
function M.show_history()
    require("anrcy.history_manager").show()
end



return M
