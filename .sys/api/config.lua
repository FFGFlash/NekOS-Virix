local function parseValue(s)
  local n = tonumber(s)
  if n then return n end
  local b = s == 'true' or s == 'false'
  if b then return s == 'true' end
  return s
end

local config = api(0, {
  {
    type = 'choice',
    options = {
      get = {
        { type = 'setting', name = 'setting' }
      },
      set = {
        { type = 'setting', name = 'setting' },
        { name = 'value' }
      },
      info = {
        { type = 'setting', name = 'setting', required = true }
      }
    }
  }
})

function config:execute(args, action, setting, value)
  local s, e = false, 'Unknown action provided.'

  if action == 'get' then s, e = self:get(setting)
  elseif action == 'set' then s, e = self:set(setting, parseValue(value))
  elseif action == 'info' then
    s, e = self:info(setting)
    if s then
      print(string.format("Type: %s Default: %s Value: %s\n%s", s.type, tostring(s.default), tostring(s.value), s.description))
      return
    end
  end

  print(e)
  if not s then self:printUsage() end
end

function config:get(setting)
  settings.load('/.settings')
  if setting then return settings.get(setting) end
  return true
end

function config:set(setting, value)
  if setting then settings.set(setting, value) end
  settings.save('/.settings')
  return true
end

function config:info(setting)
  if not setting then return false, 'No key provided' end
  return settings.getDetails(setting)
end

function config:define(setting, options)
  settings.define(setting, options)
end

function config:init()
  self:get()
end

return config:call(...)