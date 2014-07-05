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
      r.size = r.size + 1
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
        --os.queueEvent("notif", "Crafting ".. tab.amt - effectiveAmt .." ".. name)
      end
      tab.aug = 0
    end
  end
  os.queueEvent("stock_complete")
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
    term.setCursorPos(rightPos-5,HEIGHT-2)
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.gray)
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
    BUTTONS.add(1,5,4,"ed:"..selected)
    term.setCursorPos(1,7)
    term.write("Remove Entry")
    BUTTONS.add(1,7,12,"rm:"..selected)
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
  local nl = tonumber(io.read())
  while nl == nil or nl < 1 do
    print("Input a number")
    term.write("New Level: ")
    nl = tonumber(io.read())
  end
  LEVELDICT[id].amt = nl
  os.queueEvent("notif", "New level for "..LEVELDICT[id].name..": "..n1)
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
  term.setCursorPos(leftPos,2)
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  term.write("Stocking:")
  paintutils.drawLine(leftPos,3,WIDTH,3,colors.lightGray)
  
  clearIntentList(leftPos)
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
    term.setTextColor(colors.black)
    local text = tab.name..":"..tab.amt.."@"..tab.c
    BUTTONS.add(leftPos,j + 3,WIDTH-leftPos, i)
    term.write(text)
    j = j + 1
  end
  -- ScrollBar
  if LEVELDICT.size > 0 then
    paintutils.drawLine(WIDTH,4,WIDTH,HEIGHT-1,colors.gray)
    paintutils.drawPixel(WIDTH,vheight*index/LEVELDICT.size + 4,colors.black)
  end
end

function stockerLoop()
  local tid = os.startTimer(1)
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
  local si = 1
  local selected = -1
  term.setBackgroundColor(colors.white)
  term.clear()
  paintTitleBar()
  paintMenu(selected)
  paintIntentList(si, selected)
  SCROLLS.add(math.floor(WIDTH/2-4), 4, WIDTH-1, HEIGHT-1, "intent_scroll")
  local tid = os.startTimer(2)
  os.queueEvent("notif", "Welcome!")
  while true do
    local e,p1,p2 = os.pullEvent()
    if e == "notif" then
      paintNotificationBar(p1)
    elseif e == "timer" and p1 == tid then
      term.setBackgroundColor(colors.white)
      term.setCursorPos(1,1)
      term.clearLine()
      paintTitleBar()
      paintIntentList(si, selected)
      tid = os.startTimer(15)
    elseif e == "intent_scroll" then
      si = si + p1
      if si < 1 then si = 1 end
      if si > #LEVELDICT then si = #LEVELDICT end
      paintIntentList(si, selected)
    elseif e == "button" then
      os.queueEvent("notif", "button: "..p1)
      if type(p1) == "number" then
        selected = p1
        paintIntentList(si, selected)
        paintMenu(selected)
      elseif p1 == "cancel" then
        selected = -1
        paintIntentList(si, selected)
        paintMenu(selected)
      elseif string.sub(p1,1,2) == "ed" then
        local itr = string.gmatch(p1, "%d+")
        editEntry(tonumber(itr()))
        paintMenu(selected)
        paintIntentList(si, selected)
        saveIntent(INTENTFILE)
      elseif string.sub(p1,2,3) == "rm" then
        local itr = string.gmatch(p1, "%d+")
        local n = tonumber(itr())
        paintMenu(selected)
        tid = os.startTimer(1)
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
term.clear()
-- parallel.waitForAll(stockerLoop, analyticsLoop, UILoop, notificationLoop, wirelessRequestLoop)
