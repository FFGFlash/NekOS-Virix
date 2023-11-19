local data = class()

function data:constructor(path)
  rawset(self, 'file', path)
  rawset(self, 'path', path)
  rawset(self, 'data', {})
  rawset(self, 'json', false)

  function self:exists()
    return fs.exists(rawget(self, 'path'))
  end

  function self:save()
    local data = rawget(self, 'data')
    local s, e = pcall(function() data = rawget(self, 'json') and json:stringify(data) or textutils.serialize(data, { compact = true }) end)
    if not s then return false, e end
    local file = fs.open(rawget(self, 'path'), 'w')
    file.write(data)
    file.close()
    return true
  end

  function self:move(path, force)
    force = force or false
    if force then fs.delete(path) end
    local s, e = pcall(function() fs.move(rawget(self, 'path'), path) end)
    if not s then return false, e end
    return true
  end

  local loaded, err = self()
  rawset(self, 'loaded', loaded)
  rawset(self, 'error', err)
end

function data:__call()
  if not rawget(self, 'exists')(self) then return false, 'File not found.' end
  local file = fs.open(rawget(self, 'path'), 'r')
  local raw = file.readAll()
  file.close()
  local data = {}
  local s, e = pcall(function() data = textutils.unserialize(raw) end)
  if not s then return false, e end
  if not data then
    s, e = pcall(function() data = json:parse(raw) end)
    if not s then return false, e
    elseif not data then return false, 'Unable to parse file.'
    end
    rawset(self, 'json', true)
  end
  rawset(self, 'data', data)
  return true
end

function data:__index(key)
  return rawget(self, 'data')[key] or rawget(self, key)
end

function data:__newindex(key, value)
  if type(value) == 'function' then rawset(self, key, value)
  else rawget(self, 'data')[key] = value
  end
end

function data:__len()
  return #rawget(self, 'data')
end

return data