function class(base)
  local klass, meta = {}, {}
  meta.__index = meta

  function klass:__index(k)
    if k == "super" then
      local m = getmetatable(self).super
      while m and not m.constructor do m = m.super end
      local this = self
      return function(...)
        if not m then return end
        return m.constructor(this, ...)
      end
    end
    return rawget(self, k)
  end

  function klass:__newindex(k, v)
    if k == "super" then error('Property "super" is read-only.') end
    rawset(self, k, v)
  end

  if type(base) == 'table' then
    for k,v in pairs(base) do klass[k] = v end
    meta.super = base
  end

  function meta:__newindex(k, v)
    if k == "super" then error('Property "super" is read-only.') end
    rawset(self, k, v)
  end

  function meta:__call(...)
    local inst = {}
    setmetatable(inst, self)
    if self.constructor then
      self.constructor(inst, ...)
    else
      local m = self.super
      while m and not m.constructor do m = m.super end
      if m then m.constructor(inst, ...) end
    end
    return inst
  end

  function meta:isA(klass)
    local m = getmetatable(self)
    while m do
      if m == klass then return true end
      m = m.super
    end
    return false
  end

  return setmetatable(klass, meta)
end

return class