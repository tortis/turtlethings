function barGraph(data, monitor, title, xlabel, ylabel)
  assert(type(data) == "table", "barGraph expects a table as the first argument.")
  assert(type(title) == "string", "barGraph expects a string as the third argument.")
  assert(type(xlabel) == "string", "barGraph expects a string as the fourth argument.")
  assert(type(ylabel) == "string", "barGraph expects a string as the fifth argument.")
  
  local w,h = monitor.getSize()
  monitor.clear()
  
  monitor.setCursorPos(w/2 - string.len(title)/2, 1)
  monitor.write(title)
end
