local network = api(0, {
  {
    type = 'choice',
    options = {
      lookup = {
        { name = 'protocol', required = true },
        { name = 'hostname' }
      },
      send = {
        { name = 'receiver', required = true },
        { name = 'event', required = true },
        { name = '...data' },
      },
      broadcast = {
        { name = 'event', required = true },
        { name = '...data' }
      },
      request = {
        { name = 'receiver', required = true },
        { name = 'event', required = true },
        { name = '...data' }
      }
    }
  }
})

function network:execute(flags, action, ...)
  local protocol = flags.protocol or nil
  local args = { ... }
  local s, e = false, "Invalid Action"
  if action == 'lookup' then
    s, e = self:lookup(...)
  elseif action == 'send' then 
    local receiver, event = tonumber(table.remove(args, 1)), table.remove(args, 1)
    s, e = self:send(receiver, event, protocol, table.unpack(args))
  elseif action == 'broadcast' then
    local event = table.remove(args, 1)
    s, e = self:broadcast(event, protocol, table.unpack(args))
  elseif action == 'request' then
    local receiver, event = tonumber(table.remove(args, 1)), table.remove(args, 1)
    s, e = self:request(receiver, event, protocol, table.unpack(args))
  end
  print(e)
  if not s then self:printUsage() end
end

function network:init()
  self.timeout = 15

  function self:init(protocol, timeout)
    local inst = { protocol = protocol or "NekOS", timeout = timeout or self.timeout }
    local meta = { __index = inst }

    function meta:__call(hostname)
      if hostname then
        local id = rednet.lookup(self.protocol, hostname)
        if id then return false, "Hostname already in use" end
        rednet.host(self.protocol, hostname)
        self.hostname = hostname
      end
      return true, "Network Create Successfully"
    end

    function inst:handler(callback, this)
      return function(sender, req, protocol)
        if not self:validate(protocol) then return end
        callback(this, sender, table.remove(req, 1), table.unpack(req))
      end
    end

    function inst:parse(req)
      return table.remove(req, 1), req
    end

    function inst:validate(protocol)
      return self.protocol == protocol
    end

    function inst:lookup(hostname)
      return network:lookup(self.protocol, hostname)
    end

    function inst:broadcast(event, ...)
      return network:broadcast(event, self.protocol, ...)
    end

    function inst:send(receiver, event, ...)
      return network:send(receiver, event, self.protocol, ...)
    end

    function inst:request(receiver, event, ...)
      return network:request(receiver, event, self.protocol, ...)
    end

    setmetatable(inst, meta)

    return inst
  end
end

function network:connect()
  self.connected = false
  local cid, modems = os.getComputerID(), { peripheral.find('modem') }
  for _, modem in ipairs(modems) do
    if modem.isWireless() then
      if not modem.isOpen(cid) then modem.open(cid) end
      if not modem.isOpen(65535) then modem.open(65535) end
      self.connected = true
      break
    end
  end
  return self.connected, self.connected and "Network Connected" or "Failed to Connect"
end

function network:lookup(protocol, hostname)
  if not self.connected then return false, "Invalid Network Connection" end
  if not protocol then return false, "Invalid Protocol" end
  return true, { rednet.lookup(protocol, hostname) }
end

function network:broadcast(event, protocol, ...)
  if not self.connected then return false, "Invalid Network Connection" end
  if not event then return false, "Invalid Event" end
  rednet.broadcast({ event, ... }, protocol)
  return true, "Broadcast Sent"
end

function network:send(receiver, event, protocol, ...)
  if not self.connected then return false, "Invalid Network Connection" end
  if not receiver then return false, "Invalid Receiver" end
  if not event then return false, "Invalid Event" end
  rednet.send(receiver, { event, ... }, protocol)
  return true, "Message Sent"
end

function network:request(receiver, event, protocol, ...)
  if not self.connected then return false, "Invalid Network Connection" end
  if not receiver then return false, "Invalid Receiver" end
  if not event then return false, "Invalid Event" end
  rednet.send(receiver, { event, ... }, protocol)
  local id, res = -1, nil
  repeat id, res = rednet.receive(nil, self.timeout)
  until id == receiver or id == nil
  return id == receiver, id and res or "Request Timed Out"
end

return network:call(...)