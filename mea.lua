-- ME Controller Software

function loadIntent(file)
  local f = fs.open(file, "r")
  if f == nil then
    print("The file '"..file.."' could not be loaded.")
    return
  end
  local r = {}
  r.size = 0
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
      r.size = r.size + 1
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
    if name ~= "size" then
      local effectiveAmt = ME.countOfItemType(tab.id, tab.meta) + tab.aug
      if effectiveAmt < tab.amt then
        ME.requestCrafting({id=tab.id,qty=tab.amt-effectiveAmt,dmg=tab.meta})
        os.queueEvent("notif", "Crafting ".. tab.amt - effectiveAmt .." ".. name)
      end
      tab.aug = 0
    end
  end
  if os.clock()-t0 > INTERVAL then
    os.queueEvent("notif", "Warning: the stock cycle took more time to complete than the stock interval. This is unsafe and may eventually lead to system failure.")
  end
end

function paintTitleBar()
  paintutils.drawLine(1,1,WIDTH,1, colors.blue)
  term.setTextColor(colors.white)
  term.setCursorPos(2, 1)
  term.write("bitRAKE's ME Manager")
  term.setCursorPos(WIDTH-8,1)
  term.write(textutils.formatTime(os.time(), false))
end

function paintNotificationBar(msg)
  paintutils.drawLine(1,HEIGHT,WIDTH,HEIGHT, colors.lightGray)
  term.setCursorPos(2, HEIGHT)
  term.setTextColor(colors.black)
  term.write(msg)
end

function paintMenu()
  term.setCursorPos(2,3)
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.gray)
  term.write("Button 1")
  BUTTONS.add(2,3,"Button 1",  "btn1")
end

function paintIntentList(index)
  local leftPos = WIDTH/2
  local vheight = HEIGHT-4
  paintutils.drawLine(leftPos-1, 2, leftPos-1, HEIGHT-1, colors.gray)
  term.setCursorPos(leftPos,2)
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  term.write("Stocking:")
  paintutils.drawLine(leftPos,3,WIDTH,3,colors.gray)
  if LEVELDICT.size > 0 then
    paintutils.drawPixel(WIDTH,vheight*index/LEVELDICT.size+ 3,colors.black)
  end
  local i = 1
  for name, tab in pairs(LEVELDICT) do
    if i >= index and i <= i+vheight then
      if name ~= "size" then
        local c = ME.countOfItemType({tab.id,tab.meta})
        term.setCursorPos(leftPos, i + 3)
        if c < tab.amt then
          term.setBackgroundColor(colors.red)
        else
          term.setBackgroundColor(colors.green)
        end
        term.setTextColor(colors.black)
        term.write(name.." : "..tab.amt.." @ "..c)
      end
    end
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
  term.setBackgroundColor(colors.white)
  term.clear()
  paintTitleBar()
  paintMenu()
  paintIntentList(1)
  local tid = os.startTimer(15)
  --os.queueEvent("notif", "Welcome!")
  while true do
    local e,p1,p2 = os.pullEvent()
    if e == "notif" then
      paintNotificationBar(p1)
    elseif e == "timer" and p1 == tid then
      term.setBackgroundColor(colors.white)
      term.setCursorPos(1,1)
      term.clearLine()
      paintTitleBar()
      tid = os.startTimer(15)
    end
  end
end

function inputLoop()
  while true do
    local e, p1, p2, p3 = os.pullEvent()
    if e == "mouse_click" then
      if BUTTONS[p2][p3] ~= nil then
        os.queueEvent("notif", "Button Clicked: "..BUTTONS[p2][p3])
      end
    elseif e == "mouse_scroll" then
      --do nothing
    end
  end
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
WIDTH, HEIGHT = term.getSize()
LEVELDICT = loadIntent(args[2])
BUTTONS = {}
for i=1,WIDTH do
  BUTTONS[i] = {}
end
function BUTTONS.add(x, y, text, name)
  for i=1,string.len(text) do
    BUTTONS[x+i-1][y] = name
  end
end

parallel.waitForAll(stockerLoop, UILoop, inputLoop)
-- parallel.waitForAll(stockerLoop, analyticsLoop, UILoop, notificationLoop, wirelessRequestLoop)
