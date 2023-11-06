local class = require('class')

local api = class()

function api:constructor(priority, completion)
  local usage = nil

  if type(completion) == 'table' then
    completion, usage = getmetatable(self):buildCompletions(completion)
  end

  self.__priority = priority
  self.__completion = completion
  self.__usage = usage
  self.__name = ''

  function self:printUsage()
    if not self.__usage then return end
    print(self.__name)
    for i, usage in ipairs(self.__usage) do
      print(self.__name..' '..usage)
    end
  end

  function self:call(...)
    local argv = {...}
    if argv[1] and argv[2] and fs.getName(argv[1]..'.lua') == fs.getName(argv[2]) then
      self.__name = string.match(fs.getName(argv[2]), '([^\.]+)')
      if not self.__completion then return end
      shell.setCompletionFunction(argv[2], self.__completion)
      return
    elseif not self.execute then
      return
    end

    local args = { ['_'] = {} }
    for i = 1, #argv, 1 do
      local arg = argv[i]
      if arg == '.' then arg = nil end
      if string.startsWith(arg, '--') then
        local nxt = argv[i + 1]
        if nxt and not string.startsWith(nxt, '--') then
          if nxt == '.' then nxt = nil end
          args[arg] = nxt
          i = i + 1
        else
          args[arg] = true
        end
      else
        table.insert(args['_'], arg)
      end
    end

    local name = shell.getRunningProgram()
    if args['--focus'] then
      local id = multishell.getCurrent()
      multishell.setFocus(id)
      name = multishell.getTitle(id)
    end
    name = string.match(fs.getName(name), '([^\.]+)')
    self.execute(_G[name], args, table.unpack(args['_']))
  end
end

function api:__call(...)
  return self.init and self:init(...) or self
end

function api:load()
  local apis = {}
  for i, file in ipairs(fs.list('.sys/api')) do
    local name = string.match(fs.getName(file), '([^\.]+)')
    local api = require('api/'..name)
    if type(api) ~= 'table' or api.__priority == nil then
      _G[name] = api
      self.List[name] = _G[name]
    else apis[name] = api
    end
  end

  for name, api in spairs(apis, function(a, b)
    return a.__priority < b.__priority
  end) do
    _G[name] = api()
    self.List[name] = _G[name]
  end

  path:add('/.sys/api', 2)
end

function api:buildCompletions(tree)
  local function constructUsage(tree)
    local function simplifier(group)
      local res = {}
      for i, option in ipairs(group) do
        if option.type == 'choice' then
          for choice, cgroup in pairs(option.options) do
            local cres = simplifier(cgroup)
            table.insert(cres, 1, choice)
            table.insert(res, cres)
          end
        else
          table.insert(res, option.required and '<'..option.name..'>' or '['..option.name..']')
        end
      end
      return res
    end

    local function parser(a)
      local res, str, pre =  {}, true, ''
      if type(a) == 'table' then
        for i, v in ipairs(a) do
          if type(v) ~= 'string' then
            str = false
            local b = parser(v)
            for j, w in ipairs(b) do
              table.insert(res, pre..w)
            end
          else
            pre = pre..v..' '
          end
        end
        if str then table.insert(res, table.concat(a, ' ')) end
      elseif type(a) == 'string' then
        table.insert(res, a)
      end
      return res
    end

    local res = simplifier(tree)
    local usage = {}

    for i,v in ipairs(res) do
      table.combine(usages, parser(v))
    end

    return usages
  end

  local function helper(shell, index, current, args)
    local function find(tree, offset)
      offset = offset or 0
      if not tree then return {} end
      for i, v in ipairs(tree) do
        if offset + i == index then
          return v
        elseif v.type == 'choice' then
          offset = offset + i
          return find(v.options[args[offset + 1]], offset)
        end
      end
      return {}
    end

    local cur = find(tree)
    if not cur.type or not Completions[cur.type] then return {} end
    local a = { current, cur.space or false }
    if cur.options then table.insert(a, 2, table.keys(cur.options)) end
    return Completions[cur.type](table.unpack(a))
  end

  return helper, constructUsage(tree)
end

_G.Completions = require("cc.completion")
_G.api = api

function Completions.api(text, space)
  return Completions.choice(text, table.keys(api.List), space)
end

return api