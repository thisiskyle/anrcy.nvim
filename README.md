# Anrcy - Another Neovim Rest Client... Yo

<br>
<br>

## About

Another REST client plugin for Neovim

Essentially just a plugin for turning lua tables into curl commands. And while there
are many plugins that solve this issue, I felt that many of those were simply overkill for
my use case.

When creating this I had a few goals in mind: 

- Easily sketch out a request and run it from anywhere.
  Wether it is in a comment or a dedicated file, if you can highlight 
  it, you can run it.

- Write tests in lua for easy neovim compatibility without outside
  dependencies.

- Simple, familiar UI. 
  Everything comes out in a single buffer for each response, easily naviagted
  and manipulated with standard vim motions.


<br>
<br>

---

<br>

[Installation](#installation)  
[Configuration](#configuration)  
[Usage](#usage)  
[Commands](#commands)  
[Sourcing Job Files](#source)  
[Job Examples](#examples)  
[Testing Response Data](#tests)  

<br>

---

<br>
<br>

## Installation <a id="installation"></a>

Lazy:

```lua
{
    "thisiskyle/anrcy",
    opts = {},
}
```

vim.pack:

```lua
vim.pack.add({ src = "https://github.com/thisiskyle/anrcy" })
```

<br>
<br>


## Configuration <a id="configuration"></a>

```lua
    ---@type anrcy.Config    
    {
        -- (optional) global version of anrcy.Job.after and will run for 
        -- all jobs
        -- NOTE: anrcy.Job.after takes priority if set
        --
        ---@type fun(string[]): string[]
        global_after = nil,
    }
```


<br>
<br>


## Usage <a id="usage"></a>

Anrcy uses lua tables to build curl commands. You use neovim to visually highlight the table(s) and run `:'<,'>Anrcy` 
The response data, test results, and anything else returned from the request will be displayed in its own buffer. One request, one buffer.

Internally, your highlighted text is wrapped in an array and inserted into a temp file that looks like the example below.
This file is the executed using `dofile()` and the returned job array is used.  

<br>

```lua
-- temporary file
return {
    { 
        name = "job A", 
        type = "GET",
        url = "https://whatever.com"
    }
}
```

<br>


And since you run Anrcy by visually highlighting a block, your request table can be stored as text anywhere.
Here is an example of a request stored in a comment above a function call for easy testing.

<br>

```js
// Visually highlight the lua portion of the comment and run :'<,'>Anrcy to see the results.

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



### Anrcy API

Anrcy also exposes some helpful functions for use directly in lua code. 

For example, you can make a keymap that makes a specific request like this:

```lua
vim.keymap.set(
    { 'n' },
    '<leader>d',
    function()
        require("anrcy").process_jobs({
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

You can also call the `anrcy.job_handler` directly and bypass displaying the response so you can handle the data 
yourself.


```lua
require("anrcy.job_handler").async(
    {
        {
            name = "ditto",
            type = "GET",
            url = "https://pokeapi.co/api/v2/pokemon/ditto",
        }
    },
    function(responses)
        -- do work here...
    end
)
```

```lua
---@type anrcy.Response[]
local responses = require("anrcy.job_handler").sync({
    {
        name = "ditto",
        type = "GET",
        url = "https://pokeapi.co/api/v2/pokemon/ditto",
    }
})

-- do work here...

```


<br>
<br>

## Commands <a id="commands"></a>


|Command|Description|
|-------|-----------|
|:'<,'>Anrcy|Run the highlighted jobs|
|:'<,'>Anrcy bookmark_set|Bookmark the highlighted jobs|
|:'<,'>Anrcy show_curl|Display the curl commands created by the highlighted jobs (does not run curl command)|
|:'<,'>Anrcy quick_get|Run a quick curl GET request on the highlighted url|
|:Anrcy bookmark_run|Run the currently bookmarked jobs|
|:Anrcy repeat|Repeat the last job that was run|
|:Anrcy template|Insert a job template at the cursor location|
|:Anrcy clear|Clear any running or cached jobs|
|:Anrcy history|View job history. Hit enter to run the job at cursor location|

<br>
<br>


## anrcy.Job Template <a id="job-template"></a>


Most of the fields for the job template are optional, `type` and `url` are all that is required.


```lua
---@type anrcy.Job
{ 
    --- (optional) name of the job, will be used to name the response buffer
    ---@type string
    name = "", 

    --- (optional) full path of a job file to source, more info below
    ---@type string
    source = "", 

    --- (required) request type  [ "GET", "POST", etc ]
    ---@type string
    type = "",

    --- (required) request url
    ---@type string
    url = "",

    --- (optional) full curl command, this will override everything else and be used to make request
    ---@type string
    command = "",

    --- (optional) array of header strings
    ---@type string[]
    headers = { },

    --- (optional) show the curl command that is created from this job
    --- in the results buffer
    ---@type boolean
    show_curl = false, 

    --- (optional) request body / url params
    ---@type anrcy.Request_Data[]
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
        ---@type string[]
        standard = {},

        --- (optional) in the curl command, add '--data-binary' prefix before the string 
        ---@type string
        binary = {},

    },

    --- (optional) array of additional curl arguments as strings
    --- currently additional arguments act a bit wierd
    --- for some reason, this will likely break: 
    ---
    ---     addition_args = {
    ---         "-u username:password"
    ---     }
    ---
    --- splitting it into two strings is the best way to get
    --- consistent results:
    ---
    ---     addition_args = {
    ---         "-u", "username:password"
    ---     }
    --- 
    ---@type string[]
    additional_args = {},

    --- (optional) runs after the response is loaded into the buffer, used for formatting
    ---@type fun(string[]): string[]
    after = nil,

    --- (optional) runs last, runs tests against the reponse data
    ---@type fun(string[]): anrcy.Test_Result[]
    test = nil,
},
```

<br>
<br>


## Sourcing Job Files <a id="source"></a>

If you want to do something more complex, you can create a "job file."
A job file can be any valid lua file that returns an `anrcy.Job[]`

Example:

```lua
-- job_file_example.lua

--@type anrcy.Job[]
local jobs = {}

local pokemon = { "mew", "mewtwo" }

for _,v in ipairs(pokemon) do
    jobs[#jobs + 1] = {
        name = v,
        type = "GET",
        url = "https://pokeapi.co/api/v2/pokemon/" .. v,
    }
end

return jobs
```

```lua
-- anrcy.Job to run the above file
{
    source = "/full/path/to/job_file_example.lua"
}
```

Highlighting the job above and executing `:'<,'>Anrcy` will execute the 
lua file at `source` and add any returned jobs to the queue.

In the above example, two jobs will be added.

<br>
<br>

## anrcy.Job Examples <a id="examples"></a>


```lua
-- generated curl: 
-- curl -s -X GET --get https://pokeapi.co/api/v2/pokemon/pikachu

{ 
    name = "pikachu", 
    type = "GET", 
    url = "https://pokeapi.co/api/v2/pokemon/pikachu", 
}, -- this comma is important when highlighting multiple jobs

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
    after = function(payload) 
        -- use jq to format the json response
        -- requires jq to be installed on your system
        local out = vim.fn.system({ "jq", "." }, table.concat(payload))
        return vim.split(out, "\n", { plain = true })
    end,

    test = function(data) 

        -- import anrcy.assert for some test helper functions
        local assert = require("anrcy.assert")

        local name_is_ditto = assert.data_contains(data, 'name.*ditto') 

        return {
            {
                -- assumes response data will be json, follows a path and checks the key's value
                name = "",
                result = assert.json_path_equals(data, { "abilities", 1, "ability", "name" }, "limber")
            },
            {
                -- assumes response data will be json, follows a path and checks if a key exists
                name = "has a name key",
                result = assert.json_path_exists(data, { "abilities", 1, "ability", "name" })
            },
            { 
                -- searches the data for a pattern
                name = "name is ditto",
                result = name_is_ditto
            }
        }
    end
}, --- this comma is important when highlighting multiple jobs

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
}, --- this comma is important when highlighting multiple jobs

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
        "Content-Type:application/json"
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
}, --- this comma is important when highlighting multiple jobs

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
}, --- this comma is important when highlighting multiple jobs

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
        "Content-Type:application/x-www-form-urlencoded"
    },
    data = {
        -- prefixed by '--data' in the curl command
        standard = {
            "name=anrcy",
            "age=30"
        }
    },
}, --- this comma is important when highlighting multiple jobs

```

<br>
<br>

```lua

{
    name = "get with additional args",
    type = "GET",
    url = "https://something.something.com",
    additional_args = {
        "-u", "username:password",
        "-o", "out.text"
    }
}

```

<br>
<br>

```lua
-- if you want to get weird with it...
-- this IIFE returns a job table and takes in a parameter
-- useful if you are making the same call often but 
-- want to control some part of it.

-- You can highlight this function and run it like a normal job.

(function(pokemon)
    return {
        name = pokemon,
        type = "GET",
        url = "https://pokeapi.co/api/v2/pokemon/" .. pokemon,
        test = function(data)
            local assert = require("anrcy.assert")
            return {
                {
                    name = "name is " .. pokemon,
                    result = assert.json_path_equals(data, { "name" }, pokemon)
                },
            }
        end
    }
end)("charizard"),

```

<br>
<br>

## Testing Response Data <a id="tests"></a>

Anrcy supports testing the request response using the `anrcy.Job.Test` function. This function is expected to return a `arncy.Test_Result[]`

A few helper functions for parsing through the response is provided with `require("anrcy.assert")`

Example Test Function:

```lua
test = function(data) 

    local assert = require("anrcy.assert")

    local can_use_limber = assert.json_path_equals(data, { "abilities", 1, "ability", "name" }, "limber")

    return {

        { 
            name = "pokemon is named ditto",
            result = assert.data_contains(data, 'name.*ditto')
        },

        {
            name = "is pokemon able to use limber?",
            result = can_use_limber
        },

    }

end
```
