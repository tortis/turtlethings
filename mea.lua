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
      local index = 1
      local name
      for i in string.gmatch(line, "[a-zA-Z%s]+") do
        name = i
      end
      
      local le = {}
      for i in string.gmatch(line, "%d+") do
        le[index] = i
        index = index + 1
      end
      r[name] = {}
      r[name].id = le[1]
      r[name].meta = le[2]
      r[name].amt = le[3]
    end
    line = f.readLine()
  end
  return r
end

function stockerLoop()
  local jobs = me.getJobList()
  for k,v in pairs(jobs) do
    if levelDict[v.name] ~= nil then
      levelDict[v.name].aug = v.qty
    end
  end
  --local tid = os.startTimer(10)
  --local e,p1,p2,p3 = os.pullEvent()
  --if e == "timer" and p1 == tid then
    for name, tab in pairs(levelDict) do
      if me.countOfItemType(tab.id, tab.meta) + tab.aug < tab.amt then
        print("Need to craft ".. tab.amt - me.countOfItem(tab.id, tab.meta) + tab.aug .. name)
      end
      tab.aug = 0
    end
  --end
end

-- Main Program
 
local args = {...}
if #args < 1 then
  print("Usage")
  return
end
 
me = peripheral.wrap(args[1])
if me == nil then
  print("No peripheral was found on the specified side.")
  return
end
 
levelDict = loadIntent(args[2])
print(textutils.serialize(levelDict ))
stockerLoop()
