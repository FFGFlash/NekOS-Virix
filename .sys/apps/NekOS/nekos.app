local nekos = app()

function nekos:init(pwd, ...)
  self.views = {}
  self.pwd = pwd
  self.user = data(fs.combine(pwd, '.user'))
  local viewsPath = fs.combine(pwd, 'views')
  for _, view in ipairs(fs.files(viewsPath)) do
    local name = string.match(fs.getName(view), "([^\.]+)")
    local path = fs.combine(viewsPath, view)
    package.loaded[path] = nil
    self.views[name] = require(path)(self, pwd, ...)
  end

  self:setView(self.user:exists() and "login" or "setup")

  -- self:disconnectAll("terminate")
end

function nekos:setView(name)
  local view = self.views[name]
  if not view then return false, 'Invalid View' end
  if self.view then self.view:destroy() end
  self.view = view
  self.view:build()
  return true
end

function nekos:draw()
  term.setTextColor(system:getColor('text'))
  term.setBackgroundColor(system:getColor('background'))
  if not self.view then
    term.clear()
    term.writeCentered("Invalid View")
    return
  end
  self.view:draw()
  term.setTextColor(system:getColor('text'))
  term.setBackgroundColor(system:getColor('background'))
end

return nekos