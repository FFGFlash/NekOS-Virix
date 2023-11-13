local nekos = app()

function nekos:init()
  self.x, self.y = 0, 0
  self:connect('mouse_click', function(btn, x, y)
    self.x, self.y = x, y
  end)
  -- self:disconnectAll("terminate")
end

function nekos:draw()
  term.setTextColor(system:getColor('text'))
  term.setBackgroundColor(system:getColor('background'))
  term.clear()
  term.setCursorPos(1, 1)
  paintutils.drawPixel(self.x, self.y, colors.white)
end

return nekos