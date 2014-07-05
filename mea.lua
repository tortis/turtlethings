-- ME Controller Software

function loadIntent(file)
  local f = fs.open(file, "r")
  if f == nil then
    print("The file '"..file.."' could not be loaded.")
    return {}
  end
  local r = {}
  local line = f.readLine()
  local n = 1
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
      r[n] = {}
      r[n].id = tonumber(le[1])
      r[n].name = name
      r[n].meta = tonumber(le[2])
      r[n].amt = tonumber(le[3])
      r[n].aug = 0
      r[n].c = 0
      n = n + 1
    end
    line = f.readLine()
  end
  f.close()
  return r
end

function saveIntent(file)
  local f = fs.open(file, "w")
  assert (f ~= nil, "The intent file could not be opened to write to.")
  for i,tab in ipairs(LEVELDICT) do
    f.writeLine(tab.name..":"..tab.id..":"..tab.meta..":"..tab.amt)
  end
  f.close()
end

function stockCycle()
  local t0 = os.clock()
  local jobs = ME.getJobList()
  local jobsNameMap = {}
  for k,v in pairs(jobs) do
    jobsNameMap[v.name] = v.qty
  end
  for _, tab in ipairs(LEVELDICT) do
    if tab.name ~= "size" then
      tab.c = ME.countOfItemType(tab.id, tab.meta)
      if jobsNameMap[tab.name] ~= nil then
        tab.cc = jobsNameMap[tab.name]
      else
        tab.cc = 0
      end
      local effectiveAmt = tab.c + tab.cc
      if effectiveAmt < tab.amt then
        ME.requestCrafting({id=tab.id,qty=tab.amt-effectiveAmt,dmg=tab.meta})
      end
      tab.aug = 0
    end
  end
  os.queueEvent("stock_complete")
  if os.clock()-t0 > INTERVAL then
    os.queueEvent("notif", "Warning: the stock cycle took more time to complete than the stock interval. This is unsafe and may eventually lead to system failure.")
  end
end

function getString()
  local n = io.read()
  while n == nil or n == "" do
    print("Input somehting")
    term.write(" : ")
    n = io.read()
  end
  return n
end

function getNumber()
  local n = tonumber(io.read())
  while n == nil or n < 0 do
    print("Input a number")
    term.write(" : ")
    n = tonumber(io.read())
  end
  return n
end

function paintTitleBar()
  paintutils.drawLine(1,1,WIDTH,1, colors.blue)
  term.setTextColor(colors.white)
  term.setCursorPos(2, 1)
  term.write("bitRAKE's ME Manager")
  term.setCursorPos(WIDTH-8,1)
  term.write(textutils.formatTime(os.time(), false))
end

function paintNotificationBar(msg, cap)
  paintutils.drawLine(1,HEIGHT,WIDTH,HEIGHT, colors.lightGray)
  term.setCursorPos(2, HEIGHT)
  term.setTextColor(colors.black)
  term.write(msg)
  local captext = cap .. "% Cap."
  term.setCursorPos(WIDTH-string.len(captext), HEIGHT)
  term.write(captext)
end

function clearMenu(width)
  for i=2,HEIGHT-1 do
    paintutils.drawLine(1,i,width,i,colors.white)
    for j=1,width do
      BUTTONS[j][i] = nil
    end
  end
end

function paintMenu(selected)
  local rightPos = math.floor(WIDTH/2-6)
  clearMenu(rightPos)
  paintutils.drawLine(1,3,rightPos,3,colors.lightGray)
  if selected < 0 then
    term.setCursorPos(1,2)
    term.setBackgroundColor(colors.white)
    term.write("Main Menu")
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.lightGray)
    term.setCursorPos(2,5)
    term.write("New Definition")
    BUTTONS.add(2,5,17, "create")
    term.setCursorPos(2,7)
    if PAUSED then
      term.write("Resume Stocking")
      BUTTONS.add(2,7,15,"resume")
    else
      term.write("Pause Stocking")
      BUTTONS.add(2,7,13,"pause")
    end
    term.setCursorPos(rightPos-5,HEIGHT-2)
    term.write("Exit")
    BUTTONS.add(rightPos-5, HEIGHT-2, 4, "exit")
  else
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.white)
    term.setCursorPos(1, 2)
    term.write(LEVELDICT[selected].name)
    term.setCursorPos(1,5)
    term.setBackgroundColor(colors.lightGray)
    term.write("Edit")
    BUTTONS.add(1,5,4,"ed")
    term.setCursorPos(1,7)
    term.write("Remove Entry")
    BUTTONS.add(1,7,12,"rm")
    term.setCursorPos(rightPos-7,HEIGHT-2)
    term.write("Cancel")
    BUTTONS.add(rightPos-7,HEIGHT-2,6,"cancel")
  end
end

function editEntry(id)
  assert(type(id) == "number", "editEntry expects a number")
  local rightPos = math.floor(WIDTH/2-6)
  clearMenu(rightPos)
  paintutils.drawLine(1,3,rightPos,3,colors.lightGray)
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  term.setCursorPos(1, 2)
  term.write("Edit "..LEVELDICT[id].name)
  term.setCursorPos(1,5)
  term.write("Current Level: "..LEVELDICT[id].amt)
  term.setCursorPos(1,6)
  term.write("New Level: ")
  local nl = getNumber()
  LEVELDICT[id].amt = nl
  os.queueEvent("notif", "New level for "..LEVELDICT[id].name..": "..nl)
end

function createEntry()
  local rightPos = math.floor(WIDTH/2-6)
  clearMenu(rightPos)
  paintutils.drawLine(1,3,rightPos,3,colors.lightGray)
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  term.setCursorPos(1,2)
  term.write("New Definition")
  term.setCursorPos(1, 5)
  print("Exact Item Name: ")
  local name = getString()
  
  clearMenu(rightPos)
  paintutils.drawLine(1,3,rightPos,3,colors.lightGray)
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  term.setCursorPos(1,2)
  term.write("New Definition")
  term.setCursorPos(1, 5)
  print("Item ID: ")
  local id = getNumber()
  
  clearMenu(rightPos)
  paintutils.drawLine(1,3,rightPos,3,colors.lightGray)
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  term.setCursorPos(1,2)
  term.write("New Definition")
  term.setCursorPos(1, 5)
  print("Item Meta (or 0): ")
  local meta = getNumber()
  
  clearMenu(rightPos)
  paintutils.drawLine(1,3,rightPos,3,colors.lightGray)
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  term.setCursorPos(1,2)
  term.write("New Definition")
  term.setCursorPos(1, 5)
  print("Stock Level: ")
  local level = getNumber()
  local next = #LEVELDICT + 1
  LEVELDICT[next] = {}
  LEVELDICT[next].name = name
  LEVELDICT[next].id = id
  LEVELDICT[next].meta = meta
  LEVELDICT[next].amt = level
  LEVELDICT[next].c = 0
  os.queueEvent("notif", "New definition for "..name)
end

function clearIntentList(leftPos)
  for j=4,HEIGHT-1 do
    paintutils.drawLine(leftPos, j, WIDTH, j, colors.white)
  end
end

function paintIntentList(index, selected)
  local leftPos = math.floor(WIDTH/2-4)
  local vheight = HEIGHT-5
  paintutils.drawLine(leftPos-1, 2, leftPos-1, HEIGHT-1, colors.gray)
  paintutils.drawLine(leftPos,2,WIDTH,2,colors.white)
  term.setCursorPos(leftPos,2)
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  if PAUSED then
    term.write("Stocking: ")
    term.setTextColor(colors.red)
    term.write("Paused")
  else
    term.write("Stocking: ")
  end
  paintutils.drawLine(leftPos,3,WIDTH,3,colors.lightGray)
  
  clearIntentList(leftPos)
  term.setTextColor(colors.black)
  local j = 1
  local tov = math.min(index+vheight, #LEVELDICT)
  for i=index,tov do
    local tab = LEVELDICT[i]
    term.setCursorPos(leftPos, j + 3)
    if tab.c < tab.amt then
      term.setBackgroundColor(colors.red)
    else
      term.setBackgroundColor(colors.green)
    end
    if i == selected then term.setBackgroundColor(colors.yellow) end
    local text = tab.name..": "..tab.c.."/"..tab.amt
    BUTTONS.add(leftPos,j + 3,WIDTH-leftPos, i)
    term.write(text)
    j = j + 1
  end
  -- ScrollBar
  if #LEVELDICT > 0 then
    paintutils.drawLine(WIDTH,4,WIDTH,HEIGHT-1,colors.gray)
    paintutils.drawPixel(WIDTH,vheight*index/#LEVELDICT + 4,colors.black)
  end
end

function stockerLoop()
  local tid = os.startTimer(1)
  local done = false
  
  while not done do
    local e,p1,p2,p3 = os.pullEvent()
    if e == "timer" and p1 == tid then
      if not PAUSED then
        stockCycle()
      end
      os.queueEvent("notif", "Ready")
      tid = os.startTimer(INTERVAL)
    end
  end
end

function UILoop()
  local si = 1
  local selected = -1
  local cap = 0
  term.setBackgroundColor(colors.white)
  term.clear()
  paintTitleBar()
  paintIntentList(si, selected)
  paintMenu(selected)
  SCROLLS.add(math.floor(WIDTH/2-4), 4, WIDTH-1, HEIGHT-1, "intent_scroll")
  local tid = os.startTimer(2)
  local captid = os.startTimer(5)
  os.queueEvent("notif", "Welcome!")
  while true do
    local e,p1,p2 = os.pullEvent()
    if e == "notif" then
      paintNotificationBar(p1, cap)
    elseif e == "timer" then
      if p1 == tid then
        term.setBackgroundColor(colors.white)
        term.setCursorPos(1,1)
        term.clearLine()
        paintTitleBar()
        paintIntentList(si, selected)
        tid = os.startTimer(INTERVAL)
      elseif pid == captid then
        local tb = ME.getTotalBytes()
        local fb = ME.getFreeBytes()
        cap = math.floor((tb-fb)/tb)
        paintNotificationBar("Ready", cap)
        captid = os.startTimer(60)
      end
    elseif e == "intent_scroll" then
      si = si + p1
      if si < 1 then si = 1 end
      if si > #LEVELDICT then si = #LEVELDICT end
      paintIntentList(si, selected)
    elseif e == "button" then
      if type(p1) == "number" then
        selected = p1
        paintIntentList(si, selected)
        paintMenu(selected)
      elseif p1 == "cancel" then
        selected = -1
        paintIntentList(si, selected)
        paintMenu(selected)
      elseif p1 == "create" then
        createEntry()
        selected = #LEVELDICT
        paintMenu(selected)
        paintIntentList(si, selected)
        saveIntent(INTENTFILE)
        tid = os.startTimer(1)
      elseif p1 == "pause" then
        PAUSED = true
        paintMenu(selected)
        paintIntentList(si, selected)
      elseif p1 == "resume" then
        PAUSED = false
        paintMenu(selected)
        paintIntentList(si, selected)
      elseif p1 == "ed" then
        editEntry(selected)
        paintMenu(selected)
        paintIntentList(si, selected)
        tid = os.startTimer(1) -- Restart the timer
      elseif p1 == "rm" then
        table.remove(LEVELDICT, selected)
        selected = -1
        paintMenu(selected)
        paintIntentList(si, selected)
        saveIntent(INTENTFILE)
        tid = os.startTimer(1) -- Restart the timer
      elseif p1 == "exit" then
        return
      end
    end
  end
end

function inputLoop()
  while true do
    local e, p1, p2, p3 = os.pullEvent()
    if e == "mouse_click" then
      if BUTTONS[p2][p3] ~= nil then
        os.queueEvent("button", BUTTONS[p2][p3])
      end
    elseif e == "mouse_scroll" then
      if SCROLLS[p2][p3] ~= nil then
        os.queueEvent(SCROLLS[p2][p3], p1)
      end
    end
  end
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
PAUSED = false
WIDTH, HEIGHT = term.getSize()
INTENTFILE = args[2]
LEVELDICT = loadIntent(INTENTFILE)
BUTTONS = {}
for i=1,WIDTH do
  BUTTONS[i] = {}
end
function BUTTONS.add(x, y, len, name)
  for i=1,len do
    BUTTONS[x+i-1][y] = name
  end
end
SCROLLS = {}
for i=1,WIDTH do
  SCROLLS[i] = {}
end
function SCROLLS.add(x1, y1, x2, y2, name)
  for i=x1, x2 do
    for j=y1,y2 do
      SCROLLS[i][j] = name
    end
  end
end

parallel.waitForAny(stockerLoop, UILoop, inputLoop)
term.setBackgroundColor(colors.black)
term.setCursorPos(1,1)
term.clear()
