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
      r[name].id = tonumber(le[1])
      r[name].meta = tonumber(le[2])
      r[name].amt = tonumber(le[3])
      r[name].aug = 0
    end
    line = f.readLine()
  end
  return r
end

function stockCycle()
  local t0 = os.clock()
  local jobs = ME.getJobList()
  for k,v in pairs(jobs) do
    if LEVELDICT[v.name] ~= nil then
      LEVELDICT[v.name].aug = v.qty
    end
  end

  for name, tab in pairs(LEVELDICT) do
    if ME.countOfItemType(tab.id, tab.meta) + tab.aug < tab.amt then
      print("Need to craft ".. tab.amt - ME.countOfItemType(tab.id, tab.meta) + tab.aug .. name)
    end
    tab.aug = 0
  end
  print("Stock cycle took ".. os.clock()-t0 .. " seconds.")
  if os.clock-t0 > INTERVAL then
    print("Warning: the stock cycle took more time to complete than the stock interval. This is unsafe and may eventually lead to system failure.")
  end
end

function stockerLoop()
  local tid = os.startTimer(INTERVAL)
  local done = false
  
  while not done do
    local e,p1,p2,p3 = os.pullEvent()
    if e == "timer" and p1 == tid then
      stockCycle()
      tid = os.startTimer(INTERVAL)
    elseif e == "pause_stock" then
      tid = 0
    elseif e == "resume_stock" then
      tid = os.startTimer(INTERVAL)
    elseif e == "stop_stock" then
      done = true
    end
  end
end

function analyticsLoop()
  -- Track storage, jobs, and make graphs
end

function UILoop()
  -- Allow the user to adjust settigns
end

function notificationLoop()
  -- Listen for notifications from the other threads and 
  -- broadcast them on various channels.
end

function wirelessRequestLoop()
  -- Interface with chat block to server requests.
end

-- Main Program
 
local args = {...}
if #args < 1 then
  print("Usage")
  return
end
 
ME = peripheral.wrap(args[1])
if ME == nil then
  print("No peripheral was found on the specified side.")
  return
end

INTERVAL = 10

LEVELDICT = loadIntent(args[2])
print(textutils.serialize(LEVELDICT ))
stockerLoop()
-- parallel.waitForAll(stockerLoop, analyticsLoop, UILoop, notificationLoop, wirelessRequestLoop)
