local cb = peripheral.wrap('left')
local me = peripheral.wrap('bottom')
local chestMapping = {}
 
 
function getUuid(id,meta)
  return id + meta * 32768
end
   
chestMapping['_chendo_'] = 0 -- down
chestMapping['svgnnblnc'] = 5 -- east
chestMapping['DOOMSNAKE'] = 4 -- west
 
while true do
  event, player, message = os.pullEvent("chat")
 
  _, _, item_id_and_meta, amount = string.find(message, "give ([%d:]+) (%d+)")
 
  if item_id_and_meta and amount then
 
    amount = tonumber(amount)
    _, _, item_id, meta = string.find(item_id_and_meta, "(%d+):(%d+)")
 
    local uuid
    local direction
 
    direction = chestMapping[player]
 
    if not direction then
      cb.tell(player, "No mapping for your chest, contact chendo")
    else
 
    if item_id and meta then
      uuid = getUuid(item_id, meta)
    else
    uuid = tonumber(item_id_and_meta)
  end
 
  if amount > 64 then
    amount = 64
  end
 
  print(uuid)
 
  retrieved_amount = me.retrieve(uuid, amount, direction)
  cb.tell(player, "Sent " .. retrieved_amount .. " of " .. item_id_and_meta)
end
end
end
