local events = class()

function events:constructor()
  self.e = {}

  function self:emit(event, ...)
    os.queueEvent(event, ...)
  end

  function self:disconnect(listener)
    table.remove(self.e[listener.event], listener.id)
  end

  function self:connect(event, callback)
    self.e[event] = self.e[event] or {}
    table.insert(self.e[event], callback)
    return { event = event, id = #self.e[event] }
  end

  function self:disconnectAll(event)
    if event then self.e[event] = nil
    else self.e = {}
    end
  end

  function self:handleEvents()
    local args = { os.pullEvent() }
    local event = table.remove(args, 1)
    if not self.e[event] then return end
    for _, callback in ipairs(self.e[event]) do callback(table.unpack(args)) end
  end
end

function events:__call()
  self:handleEvents()
end

return events