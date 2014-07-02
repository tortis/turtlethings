function barGraph(data, monitor, title, xlabel, ylabel)
  assert(type(data) == "table", "barGraph expects a table as the first argument.")
  assert(type(title) == "string", "barGraph expects a string as the third argument.")
  assert(type(xlabel) == "string", "barGraph expects a string as the fourth argument.")
  assert(type(ylabel) == "string", "barGraph expects a string as the fifth argument.")
  
  local w,h = monitor.getSize()
  monitor.setBackgroundColor(colors.black)
  monitor.clear()
  
  monitor.setCursorPos(w/2 - string.len(title)/2, 1)
  monitor.write(title)
  monitor.setCursorPos(w/2 - string.len(xlabel)/2,h)
  monitor.write(xlabel)
  
  local max = 0
  local min = 99999999999999
  local i = 1
  while i < #data and i <= w-3 do
    if data[i] > max then max = data[i] end
    if data[i] < min then min = data[i] end
    i = i + 1
  end
  monitor.setCursorPos(1,h)
  monitor.write(min)
  monitor.setCursorPos(1,1)
  monitor.write(max)
  
  local hscale = (max-min)/(h-3)
  
  i=1
  term.redirect(monitor)
  while i < #data and i <= w-3 do
    paintutils.drawLine(w-i+1, h-2, w-i+1, (h-1)-(data[i]-min)/hscale, colors.white)
    i = i + 1
  end
  term.restore()
end

