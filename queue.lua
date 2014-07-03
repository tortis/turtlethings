function new ()
  return {first = 0, last = -1}
end

function pushleft (list, value)
  local first = list.first - 1
  list.first = first
  list[first] = value
end
    
function pushright (list, value)
  local last = list.last + 1
  list.last = last
  list[last] = value
end
    
function popleft (list)
  local first = list.first
  if first > list.last then return nil end
  local value = list[first]
  list[first] = nil        -- to allow garbage collection
  list.first = first + 1
  return value
end
    
function popright (list)
  local last = list.last
  if list.first > last then return nil end
  local value = list[last]
  list[last] = nil         -- to allow garbage collection
  list.last = last - 1
  return value
end
