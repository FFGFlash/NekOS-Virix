function Completions.path(text, space)
  return Completions.choice(text, path:get(), space)
end

local path = api(2, {
  type = 'choice',
  options = {
    get = {},
    set = {
      { name = "path", required = true }
    },
    add = {
      { name = "path", required = true }
    },
    remove = {
      { type = "path", name = "path", required = true }
    }
  }
})

function path:get()
  return string.split(shell.path(), ':')
end

function path:add(path, index)
  local p = self:get()
  if table.find(p, path) then return false, "Path already exists." end
  table.insert(p, index, path)
  local s, e =  self:set(p)
  return s, s and "Successfully modified system path." or e
end

function path:remove(path)
  local p = self:get()
  local index = table.find(p, path)
  if not index then return false, "Path not found." end
  table.remove(p, index)
  local s, e = self:set(p)
  return s, s and "Successfully modified system path." or e
end

function path:set(path)
  local t = type(path)
  if t ~= 'string' and t ~= 'table' then return false, 'Invalid path type.' end
  shell.setPath(t == 'string' and path or table.concat(path, ':'))
  return true, 'Successfully set system path.'
end

path:call(...)
return path