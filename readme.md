# NekOS-Virix

The newest version of NekOS, using an updated class syntax.

## Making an API

### In-game

1. Create a file or folder in `/.sys/api`. The name of the file/folder being the name of the api.
2. If you chose to make a folder, then create a `main.lua` file.
3. Look to the API template below for an example main file.

### Github

1. Create a repository to house your code. The name of the repository will be the name of the api.
2. In the root directory create a `main.lua` file.
3. Look to the API tempalte below for an example main file.

## API Template

### Using the api class

```lua
-- The priority is used to determine when the API will be loaded into the system. The larger the number the later it'll load. (Your API should always have a higher number than it's dependancies)
local priority = 0

-- The completions table is used for building the auto-completions for command line execution
local completions = {
  {
    type = 'choice',
    options = {
      get = {},
      put = {},
      post = {},
      delete = {}
    }
  }
}

-- Create an api instance with the given priority and completions table
local Api = api(priority, completions)

function Api:init()
  -- Initialize variables that are dependant on other apis here (APIs are initialized and exposed to the global scope in-order of priority)
  self.my_var = someOtherApi:getMyVar()
end

-- Handle api execution from the command line. If not provided then the api can only be used within the lua interpretter
function Api:execute(args, action)
  -- Declare success and message variable
  local s, m = false, 'Unknown action'
  if action == 'get' then
    s, m = true, 'Successfully performed "get" action' -- Perform the 'get' action
  elseif action == 'put' then
    s, m = true, 'Successfully performed "put" action' -- Perform the 'put' action
  elseif action == 'post' then
    s, m = true, 'Successfully performed "post" action' -- Perform the 'post' action
  elseif action == 'delete' then
    s, m = true, 'Successfully performed "delete" action' -- Perform the 'delete' action
  end

  print(m)
  -- If we didn't succeed to execute the desired action then print the command usage
  if not s then self:printUsage() end
end

return Api:call(...)
```

### Exposing tables/functions/etc

If you don't want to use the api class or your api doesn't depend on another api, no worries we got you.

API files can expose anything to the global scope!

```lua
-- Extending the string API
function string.split(s, d)
  d = d or ":"
  local a = {}
  s:gsub(string.format("([^%s]+)", d), function(c) a[#a + 1] = c end)
  return a
end

return string
```

```lua
-- Create a custom iterator (this code is from the spairs api [.sys/api/spairs.lua])
return function(t, o)
  local k, i = table.keys(t), 0
  table.sort(k, not o and nil or function(a, b) return o(t[a], t[b]) end)
  return function()
    i = i + 1
    if k[i] then return k[i],t[k[i]] end
  end
end
```
