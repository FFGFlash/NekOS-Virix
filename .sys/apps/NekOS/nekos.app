local nekos = app()

function nekos:init()
  -- self:disconnectAll("terminate")
end

function nekos:draw()
  term.setTextColor(system:getColor('text'))
  term.setBackgroundColor(system:getColor('background'))
  term.clear()
  term.setCursorPos(1,1)
end

return nekos