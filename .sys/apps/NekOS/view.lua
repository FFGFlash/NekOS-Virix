local view = class()

function view:constructor()
  self.app = nil
  self.connections = {}

  function self:connect(event, callback, this)
    local connection = self.app:connect(event, callback, this or self)
    table.insert(self.connections, connection)
    return connection
  end

  function self:destroy()
    if self.cleanup then self:cleanup() end
    for _, conn in ipairs(self.connections) do self.app:disconnect(conn)
    end
  end
end

function view:__call(app, pwd, ...)
  self.app = app
  self.pwd = pwd
  if self.init then self:init(...) end
end

return view