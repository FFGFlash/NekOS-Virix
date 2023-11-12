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

function fs.recursiveFind(dir, file)
  local files = {}

  local function level(path)
    table.combine(files, fs.find(path..'/'..file))
    local dirs = fs.dirs(path)
    for _, nDir in ipairs(dirs) do level(path..'/'..nDir) end
  end

  level(dir)

  return files
end

return fs