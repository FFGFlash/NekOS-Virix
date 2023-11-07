local system = api(2, {
  {
    type = 'choice',
    options = {
      install = {},
      update = {}
    }
  }
})

function system:execute(args, action, ...)
  local a = {...}
  local s, e = false, 'Unknown action.'

  if action == 'install' then s, e = self:install()
  elseif action == 'update' then s, e = self:update()
  end

  print(e)
  if not s then self:printUsage() end
end

function system:getManifest()
  return data('/.manifest')
end

function system:update()
  local manifest = self:getManifest()
  local newManifest, s, e
  newManifest, e = github:getRepo('ffgflash', 'NekOS-Virix')
  if not newManifest then return false, e end
  if manifest.updated_at == newManifest.updated_at then return true, 'System up to date.' end
  s, e = self:install()
  return s, s and 'System updated.' or e
end

function system:install()
  local s, e = github:download('ffgflash', 'NekOS-Virix', '/', '.sys', nil, true)
  return s, s and 'System installed.' or e
end

return system:call(...)