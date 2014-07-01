-- ME Controller Software
 
function loadIntent(file)
  local f = fs.open(file, "r")
  if f == nil then
    print("The file '"..file.."' could not be loaded.")
    return
  end
  local r = {}
  local line = f.readLine()
  while line ~= nil do
    if line ~= "" then
      local le = {}
      local index = 1
      for i in string.gmatch(line, "%d+") do
        le[index] = i
        index = index + 1
      end
      r[32768*tonumber(le[2]) + tonumber(le[1])] = tonumber(le[3])
    end
    line = f.readLine()
  end
  return r
end
 
local args = {...}
if #args < 1 then
  print("Usage")
  return
end
 
local me = peripheral.wrap(args[1])
if me == nil then
  print("No peripheral was found on the specified side.")
  return
end
 
local levelDict = loadIntent(args[2])
print(textutils.serialize(levelDict ))
