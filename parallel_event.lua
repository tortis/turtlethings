function el1()
  while true do
    local e = os.pullEvent()
    print("event on el1: "..e)
  end
end

function el2()
  while true do
    local e = os.pullEvent()
    print("event on el2: "..e)
  end
end

function esnd()
  local tid = os.startTimer(5)
  while true do
    local e,p1 = os.pullEvent()
    if e == "timer" and p1 == tid then
      tid = os.startTimer(5)
    end
  end
end

parallel.waitForAll(el1, el2, esnd)
