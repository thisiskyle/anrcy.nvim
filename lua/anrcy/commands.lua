vim.api.nvim_create_user_command(
    'Anrcy',
    function()
        local jobs = require("anrcy.utils").get_visual_selection_as_lua()
        require("anrcy").process_jobs(jobs)
    end,
    { range = true }
)

vim.api.nvim_create_user_command(
    'AnrcyClear',
    function()
        require("anrcy.job_handler").clear_jobs()
    end,
    {}
)

vim.api.nvim_create_user_command(
    'AnrcyRepeat',
    function()
        local jobs = require("anrcy.history_manager").get_last()
        require("anrcy").process_jobs(jobs)
    end,
    {}
)

vim.api.nvim_create_user_command(
    'AnrcyBookmark',
    function()
        local jobs = require("anrcy.utils").get_visual_selection_as_lua()
        require("anrcy.history_manager").set_bookmark(jobs)
    end,
    { range = true }
)

vim.api.nvim_create_user_command(
    'AnrcyBookmarkRun',
    function()
        local jobs = require("anrcy.history_manager").get_bookmark()
        require("anrcy").process_jobs(jobs)
    end,
    {}
)

vim.api.nvim_create_user_command(
    'AnrcyShowCurl',
    function()
        local jobs = require("anrcy.utils").get_visual_selection_as_lua()
        require("anrcy.job_handler").show_commands_only(jobs)
    end,
    { range = true }
)

vim.api.nvim_create_user_command(
    'AnrcyTemplate',
    function()
        require("anrcy.utils").insert_template()
    end,
    {}
)

vim.api.nvim_create_user_command(
    'AnrcyHistory',
    function()
        require("anrcy.history_manager").show()
    end,
    {}
)

vim.api.nvim_create_user_command(
    'AnrcyAnimTest',
    function()
        require("anrcy.ui").animation_test(10000)
    end,
    {}
)
