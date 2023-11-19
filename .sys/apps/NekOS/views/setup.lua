local app, pwd = ...
local view = require('../view')(app)

view.structure = {
  { name = 'Username', filter = "[^(%a| )]" },
  { name = 'Password', replacer = '*', passthrough = function(s) return s and md5:hash(s) or nil end }
}

function view:build()
  self.app.user()

  self.struct = { value = nil, index = 0 }
  self.input = { value = '', index = 0, line = 1 }

  -- Prevent tab switching until user is setup
  self.timer = os.startTimer(0.25)
  self:connect('timer', self.handleTimer)
  
  -- Handle keyboard input
  self:connect('key', self.handleKeyPressed)
  self:connect('paste', self.handleInput)
  self:connect('char', self.handleInput)

  self:nextStruct()
end

function view:nextStruct()
  self.struct.index = self.struct.index + 1
  self.struct.value = self.structure[self.struct.index]
  return self.struct
end

function view:moveCursor(n)
  self.input.index = math.clamp(self.input.index + n, 0, string.len(self.input.value))
end

-- Prevent tab switching until user is setup
function view:handleTimer(c)
  if c ~= self.timer then return end
  shell.switchTab(1)
  self.timer = os.startTimer(0.25)
end

function view:handleKeyPressed(key, held)
  if key == keys.backspace then self:handleInput(0)
  elseif key == keys.delete then self:handleInput(1)
  elseif not held then
    if key == keys.enter then self:processInput()
    elseif key == keys.left then self:moveCursor(-1)
    elseif key == keys.right then self:moveCursor(1)
    end
  end
end

function view:handleInput(c)
  if not c then return end
  
  if type(c) == 'number' then
    local p = self.input.index + c
    self.input.value = string.sub(self.input.value, 1, p - 1)..string.sub(self.input.value, p + 1, -1)
    if c <= 0 then self:moveCursor(c - 1)
    end
    return
  end

  self.input.value = string.sub(self.input.value, 1, self.input.index)..c..string.sub(self.input.value, self.input.index + 1, -1)
  self:moveCursor(string.len(c))
end

function view:processInput()
  self.input.index = 0
  local w, h = term.getSize()
  if self.input.line + 1 > h then
    term.scroll(h - self.input.line)
    self.input.line = self.input.line - 1
  end
  self:draw()
  term.setCursorBlink(false)
  term.setCursorPos(1, self.input.line + 1)
  term.clearLine()
  local f = self.struct.value.filter
  if f then
    local m = string.match(self.input.value, f)
    if m then
      print('Invalid character "'..m..'" found.')
      return
    end
  end
  local p = self.struct.value.passthrough
  self.app.user[self.struct.value.name] = p and p(self.input.value) or self.input.value
  self.input.value = ''
  self.input.line = term.getCursorY()
  if self.struct.index >= #self.structure then return self.app:setView('login') end
  term.setCursorBlink(true)
  self:nextStruct()
end

function view:cleanup()
  self.app.user:save()
end

function view:draw()
  term.setCursorPos(1, self.input.line)
  term.clearLine()
  term.write(self.struct.value.name..' > ')
  local x = term.getCursorX()
  local r = self.struct.value.replacer
  term.write(r and string.gsub(self.input.value, ".", r) or self.input.value)
  term.setCursorPos(x + self.input.index, self.input.line)
end

return view