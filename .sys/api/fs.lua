function fs.dirs(root)
  local dirs = {}
  for _, file in ipairs(fs.list(root)) do
    local path = root..'/'..file
    if fs.isDir(path) then table.insert(dirs, file)
    end
  end
  return dirs
end

function fs.files(root)
  local dirs = {}
  for _, file in ipairs(fs.list(root)) do
    local path = root..'/'..file
    if not fs.isDir(path) then table.insert(dirs, file)
    end
  end
  return dirs
end

return fs