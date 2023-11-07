if not http then return nil end

local github = api(2, {
  {
    type = 'choice',
    options = {
      download = {}
    }
  }
})

github.PROXY_URL = 'https://nekos-api-dev-sprp.2.us-1.fl0.io/github/'

function github:getRepo(user, repo)
  if repo == nil or user == nil then return false, 'User and repo are required.' end
  local res = http.get(self.PROXY_URL..user..'/'..repo)
  if not res then return false, "Can't resolve manifest url." end
  return json:fromStream(res)
end

function github:download(user, repo, dpath, rpath, branch, extract)
  if repo == nil or user == nil then return false, 'User and repo are required.' end
  dpath, rpath, branch, extract = dpath or '/downloads/', rpath or '', branch or 'main', extract or false

  local function downloadManager(path, files, dirs)
    files, dirs = files or {}, dirs or {}
    local ftype, fpath, fname = {}, {}, {}
    local res = http.get(self.PROXY_URL..user..'/'..repo..'/content?branch='..branch..'&path='..path)
    if not res then return false, "Can't resolve download url." end
    res = res.readAll()
    if res ~= nil then
      for str in res:gmatch('"type":"(%w+)"') do table.insert(ftype, str) end
      for str in res:gmatch('"path":"([^\"]+)"') do table.insert(fpath, str) end
      for str in res:gmatch('"name":"([^\"]+)"') do table.insert(fname, str) end
    end
    for i, data in pairs(ftype) do
      local path = dpath..'/'
      if not extract then path = path..repo..'/' end
      if data == 'file' then
        local cpath = http.get(self.PROXY_URL..user..'/'..repo..'/'..branch..'?path='..fpath[i])
        if cpath == nil then fpath[i] = fpath[i]..'/'..fname[i] end
        path = path..fpath[i]
        if not files[path] then files[path] = { self.PROXY_URL..user..'/'..repo..'/'..branch..'?path='..fpath[i], fname[i] } end
      elseif data == 'dir' then
        path = path..fpath[i]
        if not dirs[path] then
          dirs[path] = { self.PROXY_URL..user..'/'..repo..'/'..branch..'?path='..fpath[i], fname[i]}
          downloadManager(fpath[i], files, dirs)
        end
      end
    end
    return { files = files, dirs = dirs }
  end

  local function downloadFile(path, url, name)
    local dpath = path:gmatch('([%w%_%.% %-%+%,%;%:%*%#%=%/]+)/'..name..'$')()
    if dpath ~= nil and not fs.isDir(dpath) then fs.makeDir(dpath) end
    local content = http.get(url)
    local file = fs.open(path,"w")
    file.write(content.readAll())
    file.close()
  end

  local res, err = downloadManager(rpath)
  if not res then return res, err end
  for path, data in pairs(res.files) do downloadFile(path, table.unpack(data)) end

  local meta = self:getRepo(user, repo)
  local mpath = dpath..'/'
  if not extract then mpath = mpath..repo..'/' end
  local mfile = fs.open(mpath..'.manifest', 'w')
  mfile.write(json:stringify(meta, true))
  mfile.close()

  return true
end

return github:call(...)
