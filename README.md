# Anrcy - Another Neovim Rest Client... Yo

## About

Another REST client plugin for Neovim

Essentially just a plugin for turning lua tables into curl commands.
Feature wise, Anrcy is pretty minimal and it is probably a bit clunky. Not all curl
features and flags are properly implemented but it suits my needs.

<br>

## Why?

This plugin was developed for personal use, not to fix a problem that
hasn't been fixed already. There are plenty of other, more complete plugins out there. 
For me, the other plugins were overkill and I felt that this would be a fun challenge.

When creating this I had a few goals in mind: 

- lua object structure that is easy to use in neovim
- quickly and easily "sketch" out a request and run it anywhere
- easily add tests that are run against the response
- straight forward UI - display the response and test results in a single simple buffer


<br>
<br>


## Installation

Lazy:

```lua
{
    "thisiskyle/anrcy",
    opts = {},
}
```


<br>
<br>


## Configuration

```lua
opts = {
    -- (optional) this function will be run after the response data is added to the new buffer useful for formatting the response
    -- NOTE: this will be overidden by anrcy.Job.after if one is set
    --@type fun()?
    global_after = function() end,
},
```


<br>
<br>


## Usage

Anrcy uses lua tables to build curl commands. You use neovim to visually select the table(s) and run `:Anrcy` 
The response data, test results, and anything else returned from the request will be displayed in its own buffer. One request, one buffer.

<i>NOTE: Selected text is wrapped in an array internally. So to run multiple jobs
they should be separated by a comma.<i>

Since you run Anrcy by visually selecting a block, your request table can be stored as text anywhere.
Here is an example of a request stored in a comment above a function call for quick testing.

<br>

```js
/*
 
{ 
    name = "ditto", 
    type = "GET",
    url = "https://pokeapi.co/api/v2/pokemon/ditto"
}

*/
ditto: async () => {
    const response = await fetch("https://pokeapi.co/api/v2/pokemon/ditto");
    return await response.json();
}
```

<br>

Just visually select the lua portion of the comment and run ```:Anrcy``` to see the results.


### Anrcy API


Anrcy also exposes its ```run_jobs``` function allowing you to make calls from lua code directly.

For example, you can make a keymap that makes a specific request like this:

```lua
vim.keymap.set(
    { 'n' },
    '<leader>d',
    function ()
        require("anrcy").run_jobs({
            {
                name = "ditto",
                type = "GET",
                url = "https://pokeapi.co/api/v2/pokemon/ditto",
            },
        })
    end,
    { desc = 'request ditto information' }
)
```





<br>
<br>

## Commands 

|Command|Description|
|-------|-----------|
|Anrcy|Run the currently selected jobs|
|AnrcyRepeat|Repeat the last job that was run|
|AnrcyBookmark|Save the current visually selected jobs|
|AnrcyBookmarkRun|Run the currently bookmarked jobs|
|AnrcyShowCurl|Display the curl commands created by the current visually selected jobs (does not run anything)|
|AnrcyTemplate|Insert a job template at the cursor location|
|AnrcyClear|Clear any currently running and cached jobs|

<br>
<br>

## Job Template

Most of the fields for the job template are optional, ```type``` and ```url``` are all that is required.


```lua
---@type anrcy.Job
{ 
    --- (optional) name of the job, will be used to name the response buffer
    ---@type string
    name = "", 

    --- (required) request type  [ "GET", "POST", etc ]
    ---@type string
    type = "",

    --- (required) request url
    ---@type string
    url = "",

    --- (optional) array of header strings
    ---@type string[]
    headers = { },

    --- (optional) show the curl command that is created from this job
    --- in the results buffer
    ---@type boolean
    show_cmd = false, 

    --- (optional) request body / url params
    ---@type anrcy.RequestData[]
    data = {

        --- (optional) in the curl command, add '--data-urlencode' prefix before each data string in the list
        ---@type string[]
        urlencode = {}, 

        --- (optional) in the curl command, add '--data-raw' prefix before the data
        ---@type string[]
        raw = {}, 

        --- (optional) encodes the lua table as json and will add '--data' prefix before 
        --- the data in the curl command
        ---@type table
        lua = {},

        --- (optional) in the curl command, add '--data' prefix before the string 
        ---@type string
        standard = {},

        --- (optional) in the curl command, add '--data-binary' prefix before the string 
        ---@type string
        binary = {},

    },

    --- (optional) array of additional curl arguments as strings
    ---@type string[]
    additional_args = {},

    --- (optional) runs after the response is loaded into the buffer, used for formatting
    ---@type fun(data: anrcy.ResponseData)
    after = nil,

    --- (optional) runs last, runs tests against the reponse data
    ---@type fun(data: anrcy.ResponseData): anrcy.TestResult[]
    test = nil,
},
```

<br>
<br>

## Examples

```lua
-- generated curl: 
-- curl -s -X GET --get https://pokeapi.co/api/v2/pokemon/pikachu

{ 
    name = "pikachu", 
    type = "GET", 
    url = "https://pokeapi.co/api/v2/pokemon/pikachu", 
}, -- this comma is important for selecting multiple jobs
```

<br>
<br>

```lua
-- generated curl: 
-- curl -s -i -X GET --get --header "name:value" https://pokeapi.co/api/v2/pokemon/ditto

-- more complex GET request with headers, additional args, formatting and test functions
{ 
    name = "ditto", 
    type = "GET", 
    url = "https://pokeapi.co/api/v2/pokemon/ditto", 
    headers = { 
        "name:value"
    }, 
    additional_args = {  
        "-i"
    },
    after = function(data) 
        -- example for using jq to format the json response
        vim.cmd(":%!jq")
    end,
    test = function(data) 
        -- import anrcy.assert for some test helper functions
        local assert = require("anrcy.assert")

        return {
            {
                -- assumes response data is json, follows a path and checks the key's value
                name = "",
                result = assert.json_path_equals(data, { "abilities", 1, "ability", "name" }, "limber")
            },
            {
                -- assumes response data is json, follows a path and checks if a key exists
                name = "has a name key",
                result = assert.json_path_exists(data, { "abilities", 1, "ability", "name" })
            },
            { 
                -- searches the data for a pattern
                name = "name is ditto",
                result = assert.data_contains(data, 'name.*ditto') 
            },
            { 
                -- you can use your own function if assert does not fit your needs
                name = "always true",
                result = (function()
                    -- test here....
                    return true
                end)()
            }
        }
    end
}, --- this comma is important when selecting multiple jobs
```

<br>
<br>

```lua
-- generated curl: 
-- curl -s -X GET --get --header "name:value" --data-urlencode "lean=1" --data-urlencode "param1=something" https://mockapi.com/api

{ 
    name = "get example",
    type = "GET", 
    url = "https://mockapi.com/api",
    headers = {
        "name:value"
    },
    data = {
        -- will be prefixed with '--data-urlencode' in curl command
        urlencode = {
            "lean=1",
            "param1=something" 
        }, 
    },
}, --- this comma is important when selecting multiple jobs
```

<br>
<br>

```lua
-- generated curl: 
-- curl -s -X POST --header "Content-Type: application/json" --data "{ \"Name\": \"lua multiline json string\", \"Description\": \"multiline strings work too\", } " http://localhost:8080

{ 
    name = "another post example",
    type = "POST", 
    url = "http://localhost:8080",
    headers = {
        "Content-Type: application/json"
    },
    data = {
        -- prefixed by '--data' in the curl command
        standard = {
        [[
{
    "Name": "lua multiline json string",
    "Description": "multiline strings work too",
}
        ]]
        }
    },
}, --- this comma is important when selecting multiple jobs
```

<br>
<br>

```lua
-- generated curl: 
-- curl -s -X POST --header "Content-Type: application/json" --data "{\"Name\":\"lua table example\",\"Description\":\"this will be converted to json\"}" http://localhost:8080

{ 
    name = "post example",
    type = "POST", 
    url = "http://localhost:8080",
    headers = {
        "Content-Type: application/json"
    },
    data = {
        -- lua table will be json encoded and prefixed by '--data' in the curl command
        lua = {
            Name = "lua table example",
            Description = "this will be converted to json",
        }
    },
}, --- this comma is important when selecting multiple jobs
```

<br>
<br>

```lua
-- generated curl:
-- curl -s -X POST --header "Content-Type: application/x-www-form-urlencoded" --data "name=anrcy" --data "age=30" http://localhost:8080

{ 
    name = "another post example",
    type = "POST", 
    url = "http://localhost:8080",
    headers = {
        "Content-Type: application/x-www-form-urlencoded"
    },
    data = {
        -- prefixed by '--data' in the curl command
        standard = {
            "name=anrcy",
            "age=30"
        }
    },
}, --- this comma is important when selecting multiple jobs
```

<br>
<br>
