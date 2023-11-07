local settingsApi = api(0, {
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

function settingsApi:execute(args, action, setting, value)
  local s, e = false, 'Unknown action provided.'

  if action == 'get' then s, e = self:get(setting)
  elseif action == 'set' then s, e = self:set(setting, value)
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

function settingsApi:get(setting)
  settings.load('/.settings')
  if setting then return settings.get(setting) end
  return true
end

function settingsApi:set(setting, value)
  if setting then settings.set(setting, value) end
  settings.save('/.settings')
  return true
end

function settingsApi:info(setting)
  if not setting then return false, 'No key provided' end
  return settings.getDetails(key)
end

function settingsApi:define(setting, options)
  settings.define(setting, options)
end

return settingsApi:call(...)