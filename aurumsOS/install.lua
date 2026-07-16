-- AurumOS 1.0.5 Installer with Remote Installation Support

local OS_NAME = "AurumOS"
local VERSION = "1.0.5"
local ROOT = "/x32"
local INSTALL_PROTOCOL = "aurumos-install-v1"

local W, H = term.getSize()

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function centerText(text, y)
    local x = math.max(1, math.floor((W - #text) / 2) + 1)
    term.setCursorPos(x, y or 1)
    term.write(text)
end

local function askYesNo(question)
    while true do
        term.write(question .. " (y/n): ")
        local answer = read()
        if answer:lower() == "y" then return true
        elseif answer:lower() == "n" then return false
        end
    end
end

clear()
centText("=" .. string.rep("=", #OS_NAME), 2)
centText(OS_NAME .. " " .. VERSION .. " Installer", 3)
centText("=" .. string.rep("=", #OS_NAME), 4)
term.setCursorPos(1, 6)

print("")
print("Welcome to the AurumOS installer!")
print("")

-- Create root directory
if not fs.exists(ROOT) then
    print("Creating system directory...")
    fs.makeDir(ROOT)
end

local dirs = {
    fs.combine(ROOT, "Desktop"),
    fs.combine(ROOT, "Programs"),
    fs.combine(ROOT, "system"),
    fs.combine(ROOT, "modules")
}

for _, dir in ipairs(dirs) do
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

print("System directories created.")
print("")

-- Activation
local computerId = os.getComputerID()
local activationKey = "AURUMKEY-" .. computerId .. "-" .. VERSION

print("Your Computer ID: " .. computerId)
print("Activation Key: " .. activationKey)
print("")

if askYesNo("Save activation locally?") then
    local activationFile = fs.combine(ROOT, "system/activation.key")
    local handle = fs.open(activationFile, "w")
    if handle then
        handle.write(activationKey)
        handle.close()
        print("Activation key saved.")
    else
        print("Failed to save activation key.")
    end
else
    print("Attempting to get activation from server...")
    if rednet and peripheral then
        for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
            if peripheral.getType(side) == "modem" then
                pcall(rednet.open, side)
                break
            end
        end
        
        rednet.broadcast({action = "request_activation", computerId = computerId, version = VERSION}, INSTALL_PROTOCOL)
        local timer = os.startTimer(3)
        while true do
            local event, param1, param2, param3 = os.pullEvent()
            if event == "rednet_message" and param3 == INSTALL_PROTOCOL then
                if type(param2) == "table" and param2.action == "send_activation" then
                    local activationFile = fs.combine(ROOT, "system/activation.key")
                    local handle = fs.open(activationFile, "w")
                    if handle then
                        handle.write(param2.key)
                        handle.close()
                        print("Activation received from server!")
                    end
                    break
                end
            elseif event == "timer" and param1 == timer then
                print("No server response.")
                break
            end
        end
    end
end

print("")
print("Installation complete!")
print("Rebooting...")
sleep(2)
os.reboot()
