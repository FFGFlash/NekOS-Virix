if not http then
  error("Must enable the HTTP API.")
end

local proxy_url = "https://nekos-api-dev-sprp.2.us-1.fl0.io/github/"

local function download(user, repo, dpath, rpath, branch, extract)
  -- Fail on required parameters
  if repo == nil or user == nil then return false, "User and Repo are required." end

  -- Initialize defaults if not provided
  if rpath == nil then rpath = "" end
  if dpath == nil then dpath = "/downloads/" end
  if branch == nil then branch = "main" end
  if extract == nil then extract = false end

  local function downloadManager(path, files, dirs)
    -- Initialize defaults if not provided
    if not files then files = {} end
    if not dirs then dirs = {} end

    -- Initialize variables for storing file type, path and names
    local ftype, fpath, fname = {}, {}, {}

    -- Fetch the content of a user's repository at the given branch and path
    local res = http.get(proxy_url..user.."/"..repo.."/contents/?branch="..branch.."&path="..path)
    
    -- Error if we don't receive a response
    if not res then return false, "Cannot resolve download url." end
    
    -- Read the contents of the response
    res = res.readAll()

    if res ~= nil then
      -- Parse the response into type, path and name
      for str in res:gmatch('"type":"(%w+)"') do table.insert(ftype, str) end
      for str in res:gmatch('"path":"([^\"]+)"') do table.insert(fpath, str) end
      for str in res:gmatch('"name":"([^\"]+)"') do table.insert(fname, str) end
    end

    -- Loop over all the files and generate file download urls
    for i, data in pairs(ftype) do
      local path = dpath.."/"
      if not extract then path = path..repo.."/" end

      if data == "file" then
        local content = http.get(proxy_url..user.."/"..repo.."/"..branch.."?path="..fpath[i])
        if content == nil then fpath[i] = fpath[i].."/"..fname[i] end

        path = path..fpath[i]

        if not files[path] then
          files[path] = { proxy_url..user.."/"..repo.."/"..branch.."?path="..fPath[i], fName[i] }
        end
      elseif data == "dir" then
        path = path..fpath[i]

        if not dirs[path] then
          dirs[path] = { proxy_url..user.."/"..repo.."/"..branch.."?path="..fPath[i], fName[i] }
          downloadManager(fpath[i], files, dirs)
        end
      end
    end

    -- Return all the files and directories
    return { files = files, dirs = dirs }
  end

  local function downloadFile(path, url, name)
    -- Parse the path to get the location to download the file to
    local dpath = path:gmatch('([%w%_%.% %-%+%,%;%:%*%#%=%/]+)/'..name..'$')()
    -- Make the directory if it doesn't already exist
    if dpath ~= nil and not fs.isDir(dpath) then fs.makeDir(dpath) end
    -- Download the file contents
    local content = http.get(url)
    -- Write the content to file
    local file = fs.open(path, "w")
    file.write(content.readAll())
    file.close()
  end

  local res, err = downloadManager(rpath)
  if not res then return res, err end
  for path, data in pairs(res.files) do downloadFile(path, table.unpack(data)) end

  return true
end

local res, err = download("FFGFlash", "NekOS", "/", nil, nil, true)

if not res then
  error(err)
end

os.reboot()