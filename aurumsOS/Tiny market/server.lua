local MARKET_PROTOCOL = "aurumos-market-v1"
local VERSION = "1.0.4"

local builtinApps = {
    {
        id = "hello",
        title = "Hello App",
        version = "1.0",
        files = {
            {
                path = "/x32/Programs/hello_market.lua",
                content = 'term.clear() term.setCursorPos(1,1) print("Hello from Tiny Market!") print("Press any key.") os.pullEvent("key")'
            },
            {
                path = "/x32/Desktop/Hello.link",
                content = "title=Hello\nicon=H\ntarget=/x32/Programs/hello_market.lua\n"
            }
        }
    },
    {
        id = "notepad",
        title = "Tiny Note",
        version = "1.0",
        files = {
            {
                path = "/x32/Programs/tiny_note.lua",
                content = 'local p="/x32/Desktop/note.txt" term.clear() term.setCursorPos(1,1) print("Tiny Note") write("> ") local h=fs.open(p,"a") h.writeLine(read()) h.close() print("Saved to "..p) sleep(1)'
            },
            {
                path = "/x32/Desktop/TinyNote.link",
                content = "title=TinyNote\nicon=N\ntarget=/x32/Programs/tiny_note.lua\n"
            }
        }
    }
}

local function findModem()
    for _, side in ipairs({ "top", "bottom", "left", "right", "front", "back" }) do
        if peripheral.getType(side) == "modem" then
            return side
        end
    end
    return nil
end

local function readFile(path)
    if not fs.exists(path) or fs.isDir(path) then return nil end
    local h = fs.open(path, "r")
    local text = h.readAll()
    h.close()
    return text
end

local function readUpdatePackage()
    local manifest = "packages/AurumOS/files.lst"
    if not fs.exists(manifest) then
        return nil
    end
    local files = {}
    for line in (readFile(manifest) or ""):gmatch("[^\r\n]+") do
        local target, source = line:match("^(%S+)%s+(.+)$")
        if target and source and fs.exists(source) then
            files[#files + 1] = { path = target, content = readFile(source) or "" }
        end
    end
    return files
end

local side = findModem()
term.clear()
term.setCursorPos(1, 1)
print("Tiny Market server")
print("Version " .. VERSION)

if not side then
    print("No modem found.")
    return
end

rednet.open(side)
print("ID: " .. os.getComputerID())
print("Modem: " .. side)
print("Protocol: " .. MARKET_PROTOCOL)
print("")

while true do
    local sender, message = rednet.receive(MARKET_PROTOCOL)
    if type(message) == "table" then
        if message.action == "catalog" then
            local apps = {}
            for _, app in ipairs(builtinApps) do
                apps[#apps + 1] = { id = app.id, title = app.title, version = app.version }
            end
            rednet.send(sender, { ok = true, apps = apps }, MARKET_PROTOCOL)
        elseif message.action == "install" then
            local found = nil
            for _, app in ipairs(builtinApps) do
                if app.id == message.id then found = app end
            end
            if found then
                rednet.send(sender, { ok = true, files = found.files }, MARKET_PROTOCOL)
            else
                rednet.send(sender, { ok = false, error = "App not found." }, MARKET_PROTOCOL)
            end
        elseif message.action == "update" then
            local files = readUpdatePackage()
            if files and #files > 0 then
                rednet.send(sender, { ok = true, version = VERSION, files = files }, MARKET_PROTOCOL)
            else
                rednet.send(sender, { ok = true, version = message.version or VERSION, files = {} }, MARKET_PROTOCOL)
            end
        end
    end
end
