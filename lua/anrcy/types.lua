
---@class anrcy.Animation
---@field delta_time_ms number
---@field frames string[]

---@class anrcy.Config_Opts
---@field global_after? fun(payload: string[]): string[]
---@field animation? string
---@field animations? table<string, anrcy.Animation>

---@class anrcy.Response_Data
---@field payload string[]
---@field curl_header string[]


---@class anrcy.Job_Handler
---@field sync fun(jobs: anrcy.Job[]): anrcy.Response[]
---@field async fun(jobs: anrcy.Job[], on_complete: fun(data?: anrcy.Response[]))
---@field show_commands_only fun(jobs: anrcy.Job[])


---@class anrcy.Job
---@field name string
---@field show_curl? boolean
---@field type string
---@field url string
---@field headers string[]
---@field data table[]
---@field additional_args? string[]
---@field command? string[] | string
---@field after? fun(data?: string[])
---@field test? fun(data?: string[])


---@class anrcy.Response
---@field name? string
---@field stdout? string[]
---@field stderr? string[]
---@field data? anrcy.Response_Data
---@field test_results? table
---@field curl_cmd? string[]
---@field show_curl? boolean


---@class anrcy.Display_Opts
---@field name string
---@field singleton boolean
---@field payload string[]
---@field window table vim.api.keyset.win_config


---@class anrcy.Test_Result 
---@field name string
---@field result boolean
