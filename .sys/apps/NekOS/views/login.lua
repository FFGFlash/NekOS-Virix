local app, pwd = ...
local view = require('../view')(app)

function view:build()
  self.app.user()

  self.input = { value = "", index = 0, line = 1 }
  
  if not self.user.password then return self.app:setView('menu') end

  self.timer = os.startTimer(0.25)
  self:connect('timer', self.handleTimer)

  self:connect('char', self.handleInput)
  self:connect('paste', self.handleInput)
  self:connect('key', self.handleKeyPressed)

  term.setCursorBlink(true)
  term.clear()
  term.setCursorPos(1, 1)
  term.write('Username > ')
  term.write(self.app.user.username)
end

-- Prevent tab switching until user is setup
function view:handleTimer(c)
  if c ~= self.timer then return end
  shell.switchTab(1)
  self.timer = os.startTimer(0.25)
end

function view:draw()
  term.setCursorPos(1, self.input.line)
  term.clearLine()
  term.write('Password > ')
  local x = term.getCursorX()
  term.write(string.gsub(self.input.value, '.', '*'))
  term.setCursorPos(x + self.input.index, self.input.line)
end

function view:moveCursor(c)
  self.input.index = math.clamp(self.input.index + c, 0, string.len(self.input.value))
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
    if c <= 0 then self:moveCursor(c - 1) end
    return
  end

  self.input.value = string.sub(self.input.value, 1, self.input.index)..c..string.sub(self.input.value, self.input.index + 1, -1)
  self:moveCursor(string.len(c))
end

function view:processInput()
  self.input.index = 0
  self:draw()
  term.setCursorBlink(false)
  term.setCursorPos(1, self.input.line + 1)
  if md5:hash(self.input.value) == self.app.user.password then
    self.app:setView('menu')
    return
  end
  term.write('Incorrect Password.')
  self.input.value = ''
  term.setCursorBlink(true)
end

return view