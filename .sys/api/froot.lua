local froot = api(3, {})

function froot:execute()
  print('Hi :3')
end

return froot:call(...)
