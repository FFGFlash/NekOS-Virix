local view = class()

function view:constructor(app)
  self.app = app
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

return view