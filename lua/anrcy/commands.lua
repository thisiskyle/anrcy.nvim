vim.api.nvim_create_user_command(
    'Anrcy',
    function(opts)
        local arg = opts.args
        local range = opts.range > 0 and { opts.line1, opts.line2 } or nil
        local anrcy = require("anrcy")

        if(#arg == 0 and range) then
            anrcy.run_highlighted_jobs()
            return
        end

        if(arg == 'quick_get' and range) then
            anrcy.get_highlighted_url()

        elseif(arg == 'bookmark_set' and range) then
            anrcy.set_bookmark()

        elseif(arg == 'bookmark_run') then
            anrcy.execute_bookmark()

        elseif(arg == 'clear') then
            anrcy.clear_jobs()

        elseif(arg == 'history') then
            anrcy.show_history()

        elseif(arg == 'repeat') then
            anrcy.repeat_last()

        elseif(arg == 'show_curl' and range) then
            anrcy.show_curl()

        elseif(arg == 'template') then
            anrcy.insert_template()

        else
            vim.notify(
                'Invalid command: Anrcy ' .. arg .. " while range = " .. (range or "nil"),
                vim.log.levels.ERROR
            )
        end

    end, {
        nargs = "?",
        range = true,
        complete = function(arglead)
            return vim.tbl_filter(
                function(cmd)
                    return cmd:find(arglead, 1, true) == 1
                end, {
                    'bookmark_set',
                    'bookmark_run',
                    'clear',
                    'history',
                    'quick_get',
                    'repeat',
                    'show_curl',
                    'template',
                }
            )
        end,
    }
)

