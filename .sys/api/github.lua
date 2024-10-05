if not http then return nil end

local github = api(2, {
  {
    type = 'choice',
    options = {
      download = {}
    }
  }
})

function github:getRepo(user, repo)
  if repo == nil or user == nil then return false, 'User and repo are required.' end
  local proxy_url = config:get('nekos.api') .. '/github/'
  local res = http.get(proxy_url .. user .. '/' .. repo)
  if not res then return false, "Can't resolve manifest url." end
  return json:fromStream(res)
end

function github:download(user, repo, dpath, rpath, branch, extract)
  if repo == nil or user == nil then return false, 'User and repo are required.' end

  local proxy_url = config:get('nekos.api') .. '/github/'

  local function downloadManager(path, files, dirs)
    files, dirs = files or {}, dirs or {}
    local ftype, fpath, fname = {}, {}, {}
    local res = http.get(proxy_url .. user .. '/' .. repo .. '/contents?branch=' .. branch .. '&path=' .. path)
    if not res then return false, "Can't resolve download url." end
    res = res.readAll()
    if res ~= nil then
      for str in res:gmatch('"type":"(%w+)"') do table.insert(ftype, str) end
      for str in res:gmatch('"path":"([^\"]+)"') do table.insert(fpath, str) end
      for str in res:gmatch('"name":"([^\"]+)"') do table.insert(fname, str) end
    end
    for i, data in pairs(ftype) do
      local path = dpath .. '/'
      if not extract then path = path .. repo .. '/' end
      if data == 'file' then
        local cpath = http.get(proxy_url .. user .. '/' .. repo .. '/' .. branch .. '?path=' .. fpath[i])
        if cpath == nil then fpath[i] = fpath[i] .. '/' .. fname[i] end
        path = path .. fpath[i]
        if not files[path] then
          files[path] = { proxy_url .. user .. '/' .. repo .. '/' .. branch .. '?path=' .. fpath
          [i], fname[i] }
        end
      elseif data == 'dir' then
        path = path .. fpath[i]
        if not dirs[path] then
          dirs[path] = { proxy_url .. user .. '/' .. repo .. '/' .. branch .. '?path=' .. fpath[i], fname[i] }
          downloadManager(fpath[i], files, dirs)
        end
      end
    end
    return { files = files, dirs = dirs }
  end

  local function downloadFile(path, url, name)
    local dpath = path:gmatch('([%w%_%.% %-%+%,%;%:%*%#%=%/]+)/' .. name .. '$')()
    if dpath ~= nil and not fs.isDir(dpath) then fs.makeDir(dpath) end
    local content = http.get(url)
    local file = fs.open(path, "w")
    file.write(content.readAll())
    file.close()
  end


  dpath, rpath, extract = dpath or '/downloads/', rpath or '', extract or false

  local meta, merr = self:getRepo(user, repo)
  if not meta then return false, merr end
  local mpath = dpath .. '/'
  if not extract then mpath = mpath .. repo .. '/' end
  local mfile = fs.open(mpath .. '.manifest', 'w')
  mfile.write(json:stringify(meta, true))
  mfile.close()

  branch = branch or meta.default_branch

  local res, err = downloadManager(rpath)
  if not res then return res, err end
  for path, data in pairs(res.files) do downloadFile(path, table.unpack(data)) end

  return true
end

return github:call(...)
