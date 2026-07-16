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
        if answer:lower() == "y" then 
            return true
        elseif answer:lower() == "n" then 
            return false
        end
    end
end

local function ensureDir(path)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
end

clear()
centerText("=" .. string.rep("=", #OS_NAME), 2)
centerText(OS_NAME .. " " .. VERSION .. " Installer", 3)
centerText("=" .. string.rep("=", #OS_NAME), 4)
term.setCursorPos(1, 6)

print("")
print("Welcome to the AurumOS installer!")
print("")

-- Create root directory
if not fs.exists(ROOT) then
    print("Creating system directory...")
    ensureDir(ROOT)
end

local dirs = {
    fs.combine(ROOT, "Desktop"),
    fs.combine(ROOT, "Programs"),
    fs.combine(ROOT, "system"),
    fs.combine(ROOT, "modules")
}

for _, dir in ipairs(dirs) do
    ensureDir(dir)
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
    local systemDir = fs.combine(ROOT, "system")
    ensureDir(systemDir)
    
    local activationFile = fs.combine(systemDir, "activation.key")
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
        local modemFound = false
        for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
            if peripheral and peripheral.getType(side) == "modem" then
                pcall(rednet.open, side)
                modemFound = true
                break
            end
        end
        
        if modemFound then
            rednet.broadcast({action = "request_activation", computerId = computerId, version = VERSION}, INSTALL_PROTOCOL)
            local timer = os.startTimer(3)
            local received = false
            
            while true do
                local event, param1, param2, param3 = os.pullEvent()
                if event == "rednet_message" then
                    if param3 == INSTALL_PROTOCOL and type(param2) == "table" then
                        if param2.action == "send_activation" and param2.key then
                            local systemDir = fs.combine(ROOT, "system")
                            ensureDir(systemDir)
                            
                            local activationFile = fs.combine(systemDir, "activation.key")
                            local handle = fs.open(activationFile, "w")
                            if handle then
                                handle.write(param2.key)
                                handle.close()
                                print("Activation received from server!")
                                received = true
                            end
                            break
                        end
                    end
                elseif event == "timer" and param1 == timer then
                    print("No server response. Using local activation.")
                    break
                end
            end
        else
            print("No modem found. Using local activation.")
        end
    else
        print("RedNet not available. Using local activation.")
    end
end

print("")

-- Create essential system files if they don't exist
local systemDir = fs.combine(ROOT, "system")
ensureDir(systemDir)

-- Create activation.lua if missing
local activationLuaPath = fs.combine(systemDir, "activation.lua")
if not fs.exists(activationLuaPath) then
    print("Creating activation system...")
    local activationCode = [[local activation = {}

function activation.isActivated(root, version)
    local activationFile = fs.combine(root, "system/activation.key")
    if not fs.exists(activationFile) then
        return false
    end
    
    local handle = fs.open(activationFile, "r")
    if not handle then return false end
    
    local data = handle.readAll()
    handle.close()
    
    return data and #data > 0
end

function activation.generateKey(computerId, version)
    return "AURUMKEY-" .. computerId .. "-" .. version
end

function activation.save(root, key)
    local dir = fs.combine(root, "system")
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local activationFile = fs.combine(root, "system/activation.key")
    local handle = fs.open(activationFile, "w")
    if handle then
        handle.write(key)
        handle.close()
        return true
    end
    return false
end

return activation
]]
    local handle = fs.open(activationLuaPath, "w")
    if handle then
        handle.write(activationCode)
        handle.close()
        print("Activation system created.")
    end
end

print("")
print("Installation complete!")
print("Rebooting...")
sleep(2)
os.reboot()
