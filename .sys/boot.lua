-- Prevents termination events
-- os.pullEvent = os.pullEventRaw

require('/api')

term.clear()
term.setCursorPos(1,1)

api:load()