-- Network Installation Server for AurumOS 1.0.5
-- Run this on an active computer to allow others to install via network

local INSTALL_PROTOCOL = "aurumos-install-v1"
local VERSION = "1.0.5"
local ROOT = "/x32"

print("AurumOS 1.0.5 Network Installation Server")
print("=========================================")
print("")
print("Opening modem...")

if not rednet then
    print("RedNet not available.")
    return
end

local modemSide = nil
for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral and peripheral.getType(side) == "modem" then
        modemSide = side
        break
    end
end

if not modemSide then
    print("No modem found.")
    return
end

pcall(rednet.open, modemSide)
print("Modem opened on side: " .. modemSide)
print("Listening for installation requests...")
print("")

local processedIds = {}

while true do
    local senderId, message, protocol = rednet.receive(INSTALL_PROTOCOL)
    
    if type(message) == "table" then
        if message.action == "discover_installer" then
            print("[" .. os.date("%H:%M:%S") .. "] Discovery request from computer " .. senderId)
            rednet.send(senderId, {action = "installer_ready", version = VERSION}, INSTALL_PROTOCOL)
        elseif message.action == "request_activation" then
            print("[" .. os.date("%H:%M:%S") .. "] Activation request from computer " .. message.computerId)
            local key = "AURUMKEY-" .. message.computerId .. "-" .. message.version
            rednet.send(senderId, {action = "send_activation", key = key}, INSTALL_PROTOCOL)
            print("Sent activation key: " .. key)
        end
    end
end
