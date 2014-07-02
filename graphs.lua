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
  local max = 0
  local i = 1
  while i < #data and i <= 30 do
    if data[i] > max then max = data[i] end
    i = i + 1
  end
  
  local hscale = max/(h-3)
  
  i=1
  term.redirect(monitor)
  while i < #data and i <= 30 do
    paintutils.drawLine(w-i, h-2, w-i, data[i]/hscale)
  end
  term.restore()
end
