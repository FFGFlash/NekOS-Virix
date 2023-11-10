function Completions.app(text, space)
  return Completions.choice(text, app:getApps(), space)
end

local app = api(2, {
  {
    type = 'choice',
    options = {
      install = {
        { name = 'user', required = true },
        { name = 'repo', required = true },
        { name = 'branch', required = false }
      },
      uninstall = {
        { type = 'app', name = 'app', required = true }
      },
      update = {
        { type = 'app', name = 'app', required = true }
      },
      run = {
        { type = 'app', name = 'app', required = true },
        { name = 'args...' }
      }
    }
  }
})

function app:getApps()
  return fs.recursiveFind('/', '*.app')
end

function app:init()
  return 'test'
end

function app:execute(flags, action, app, ...)
  local s, e = false, "Invalid Action"
  if action == 'install' then
  elseif action == 'uninstall' then
  elseif action == 'update' then
  elseif action == 'run' then
  end
  print(e)
  if not s then self:printUsage() end
end

return app:call(...)