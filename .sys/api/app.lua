function Completions.app(text, space)
  return Completions.choice(text, app:getApps(), space)
end

local app = api(2, {
  {
    type = 'choice',
    options = {
      install = {
        { name = 'user', required = true },
        { name = 'repo', required = true }
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

function app:getManifest(app)
  local dir = fs.getDir(app)
  local path = dir..'/.manifest'
  if not fs.exists(path) or fs.isDir(path) then return false, 'Manifest Not Found.' end
  return data(path)
end

function app:getApps()
  return fs.recursiveFind('/', '*.app')
end

function app:install(user, repo, path)
  if not fs.exists('/apps') then fs.mkdir('/apps') end
  local s, e = github:download(user, repo, path or '/apps', nil, nil, false)
  return s, s and 'App installed.' or e
end

function app:update(app)
  local manifest, newManifest, s, e
  manifest, e = self:getManifest(app)
  if not manifest then return false, e end
  local user, repo = manifest.owner.login, manifest.name
  newManifest, e = github:getRepo(user, repo)
  if not newManifest then return false, e end
  if manifest.pushed_at == newManifest.pushed_at then return true, 'App up to date.' end
  s, e = self:install(user, repo)
  return s, s and 'App updated.' or e
end

function app:run(app, flags, ...)
  local manifest = self:getManifest(app)
  if manifest and manifest.full_name then
    self:update(app)
    manifest()
  end
  local inst = require(app)(app, flags, ...)
  inst:start()
  return true, 'App running'
end

function app:init()
  self.updateMap = data('.app_update_map')

  function self:init()
    local appBase = class(events)

    function appBase:constructor(id, ...)
      self.super()
      self.running = false
      self.id = id

      function self:start()
        self.running = true
        while self.running do
          local function drawLoop()
            if not self.draw then return end
            self:draw()
          end

          local function eventLoop()
            self:handleEvents()
          end

          parallel.waitForAll(drawLoop, eventLoop)
        end
      end

      function self:stop()
        self.running = false
        self:emit('stop')
      end

      self:connect('terminate', function() self:stop() end)
      if self.init then self:init(...) end
    end

    return appBase
  end
end

function app:execute(flags, action, ...)
  local s, e = false, "Invalid Action"
  if action == 'install' then s, e = self:install(...)
  elseif action == 'uninstall' then s, e = self:uninstall(...)
  elseif action == 'update' then s, e = self:update(...)
  elseif action == 'run' then
    local args = {...}
    s, e = self:run(table.remove(args, 1), flags, table.unpack(args))
  end
  print(e)
  if not s then self:printUsage() end
end

return app:call(...)