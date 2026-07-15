local OS_NAME = "AurumOS"
local VERSION = "1.0.4"
local INSTALL_ROOT = "/x32"
local ACTIVATION_PROTOCOL = "aurumos-activation-v1"

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function readAll(path)
    if not fs.exists(path) then
        return nil
    end
    local handle = fs.open(path, "r")
    if not handle then
        return nil
    end
    local text = handle.readAll()
    handle.close()
    return text
end

local function samePath(a, b)
    a = fs.combine("/", tostring(a or "")):gsub("^/+", ""):gsub("/+$", "")
    b = fs.combine("/", tostring(b or "")):gsub("^/+", ""):gsub("/+$", "")
    return a == b
end

local function ensureDir(path)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
end

local function copyTree(source, target)
    if samePath(source, target) then
        return
    end

    if fs.isDir(source) then
        ensureDir(target)
        for _, name in ipairs(fs.list(source)) do
            copyTree(fs.combine(source, name), fs.combine(target, name))
        end
        return
    end

    local parent = fs.getDir(target)
    if parent and parent ~= "" then
        ensureDir(parent)
    end
    if fs.exists(target) then
        fs.delete(target)
    end
    fs.copy(source, target)
end

local function writeStartupFile(path)
    local bootLine = 'shell.run("/x32/boot.lua")'
    local old = readAll(path)
    if old and not old:find('/x32/boot.lua', 1, true) then
        local backup = path .. ".before_x32"
        if not fs.exists(backup) then
            fs.copy(path, backup)
        end
    end

    local handle = fs.open(path, "w")
    handle.writeLine(bootLine)
    handle.close()
end

local function writeStartup()
    writeStartupFile("/startup")
    writeStartupFile("/startup.lua")
end

local function yesNo(prompt, defaultYes)
    while true do
        write(prompt)
        local value = tostring(read() or ""):lower()
        if value == "" and defaultYes ~= nil then
            return defaultYes
        end
        if value == "y" or value == "yes" or value == "d" or value == "da" then
            return true
        end
        if value == "n" or value == "no" or value == "net" then
            return false
        end
        print("Type y or n.")
    end
end

local function modemSides()
    if redstone and redstone.getSides then
        return redstone.getSides()
    end
    return { "top", "bottom", "left", "right", "front", "back" }
end

local function requestKeyFromServer()
    if not rednet or not peripheral then
        return nil, "rednet is not available"
    end

    local opened = false
    for _, side in ipairs(modemSides()) do
        if peripheral.getType(side) == "modem" then
            pcall(rednet.open, side)
            opened = true
            break
        end
    end

    if not opened then
        return nil, "no modem found"
    end

    rednet.broadcast({ version = VERSION }, ACTIVATION_PROTOCOL)
    local _, message = rednet.receive(ACTIVATION_PROTOCOL, 4)
    if type(message) == "table" and message.ok and message.key then
        return message.key
    end
    return nil, "no activation server answered"
end

local runningProgram = shell and shell.getRunningProgram and shell.getRunningProgram() or "install.lua"
local installerDir = fs.getDir(runningProgram)
if installerDir == "" then
    installerDir = "."
end

local sourceRoot = fs.combine(installerDir, "AurumOS")
local activationPath = fs.combine(sourceRoot, "system/activation.lua")

clear()
print(OS_NAME .. " installer")
print("")

if not fs.exists(sourceRoot) or not fs.exists(activationPath) then
    print("Install files are missing.")
    print("Put install.lua next to the AurumOS folder and run it again.")
    return
end

local activation = dofile(activationPath)
local computerId = os.getComputerID()
local key
local method

print("Computer ID: " .. tostring(computerId))
print("OS version : " .. VERSION)
print("Install dir: " .. INSTALL_ROOT)
print("")
print("Enter an activation key, or press Enter to ask")
print("activation_server.lua over rednet.")
print("")

while true do
    write("Activation key: ")
    key = read()

    if key == "" then
        print("Asking activation server over rednet...")
        local serverKey, err = requestKeyFromServer()
        if serverKey then
            key = serverKey
            print("Received key: " .. key)
        else
            print(err or "Could not get a key.")
        end
    end

    local ok, reason = activation.isValidKey(computerId, VERSION, key)
    if ok then
        method = reason
        break
    end

    print("Wrong key for this computer/version.")
    if not yesNo("Try again? [Y/n] ", true) then
        print("Install cancelled.")
        return
    end
end

print("")
print("Creating " .. INSTALL_ROOT .. " ...")
ensureDir(INSTALL_ROOT)

print("Copying OS files...")
copyTree(sourceRoot, INSTALL_ROOT)
ensureDir(fs.combine(INSTALL_ROOT, "Desktop"))
ensureDir(fs.combine(INSTALL_ROOT, "Programs"))
ensureDir(fs.combine(INSTALL_ROOT, "system"))

activation.writeFile(fs.combine(INSTALL_ROOT, "system/activation.dat"), computerId, VERSION, key, method)
writeStartup()

print("")
print("Installed to " .. INSTALL_ROOT .. ".")
print("Activation saved. Next boot opens the desktop directly.")

if yesNo("Reboot now? [Y/n] ", true) then
    os.reboot()
end
