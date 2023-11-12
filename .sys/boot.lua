local function load(modulename)
  local errmsg = ""
  for path in string.gmatch(package.path, "([^;]+)") do
    local filename = string.gsub(path, "%?", modulename)
    local file = io.open(filename, "rb")
    if file then
      -- Compile and return the module
      return assert(loadstring(assert(file:read("*a")), filename))
    end
    errmsg = errmsg.."\n\tno file '"..filename.."' (checked with custom loader)"
  end
  return errmsg
end

table.insert(package.loaders, 2, load)

os.pullEvent = os.pullEventRaw

require('api')

term.clear()
term.setCursorPos(1,1)

api:load()

local c, t, w, h = 0, 0, term.getSize()
local l = '///NekOS///'

term.setTextColor(system:getColor('text'))
term.setBackgroundColor(system:getColor('background'))
term.clear()

term.setCursorPos(math.floor((w - string.len(l)) / 2), math.floor(h / 2))
for i = 1, string.len(l) do
  term.blit(string.sub(l, i, i), string.sub(string.gsub('edb00000bde', '0', system:getBlit('text')), i, i), system:getBlit('background'))
  sleep(1 / 5)
end

sleep(1)

if config:get('nekos.auto_update') then
  local s, e = true, 'Checking for Updates'
  term.setCursorPos(math.floor((w - string.len(e)) / 2), math.floor(h / 2 + 2))
  term.clearLine()
  term.write(e)

  s, e = system:update()

  term.setCursorPos(math.floor((w - string.len(e)) / 2), math.floor(h / 2 + 2))
  term.clearLine()
  term.write(e)

  sleep(3)

  if s and e == 'System updated.' then os.reboot() end
end

term.clear()
term.setCursorPos(1, 1)