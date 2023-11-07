local data = class()

function data:constructor(path)
  self.file = path
  self.path = path
  self.data = {}
  self.json = false

  function self:exists()
    return fs.exists(rawget(self, 'path'))
  end

  function self:raw()
    return rawget(self, 'data')
  end

  function self:save()
    local data = self.data
    local s, e = pcall(function() data = self.json and json:stringify(data) or textutils.serialize(data, { compact = true }) end)
    if not s then return false, e end
    local file = fs.open(self.path, 'w')
    file.write(data)
    file.close()
    return true
  end

  function self:move(path, force)
    force = force or false
    if force then fs.delete(path) end
    local s, e = pcall(function() fs.move(self.path, path) end)
    if not s then return false, e end
    return true
  end

  self.loaded, self.error = self()
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
  rawget(self, 'data')[key] = value
end

return data