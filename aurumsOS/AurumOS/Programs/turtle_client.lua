local PROTOCOL = "aurumos-turtle-v1"

local function findModem()
    for _, side in ipairs({ "top", "bottom", "left", "right", "front", "back" }) do
        if peripheral.getType(side) == "modem" then return side end
    end
    return nil
end

local side = findModem()
term.clear()
term.setCursorPos(1, 1)
print("AurumOS turtle client")
print("ID: " .. os.getComputerID())

if not turtle then
    print("This program must run on a turtle.")
    return
end
if not side then
    print("No modem found.")
    return
end

rednet.open(side)
print("Listening on " .. side)

local function inventory()
    local list = {}
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            list[i] = item.name .. " x" .. item.count
        else
            list[i] = "empty"
        end
    end
    return list
end

while true do
    local sender, message = rednet.receive(PROTOCOL)
    if type(message) == "table" and message.app == "AurumTurtle" then
        local cmd = message.cmd
        local ok, extra = false, ""
        if turtle[cmd] then
            ok = turtle[cmd]()
        elseif cmd == "inventory" then
            ok = true
        end
        rednet.send(sender, {
            ok = ok,
            message = cmd,
            inventory = inventory()
        }, PROTOCOL)
    end
end
