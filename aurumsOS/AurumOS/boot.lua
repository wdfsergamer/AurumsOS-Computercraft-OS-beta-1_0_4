local OS_NAME = "AurumOS"
local VERSION = "1.0.5"
local ROOT = "/x32"
local DESKTOP = fs.combine(ROOT, "Desktop")
local PROGRAMS = fs.combine(ROOT, "Programs")
local SYSTEM = fs.combine(ROOT, "system")
local MODULES = fs.combine(ROOT, "modules")

local SHARE_PROTOCOL = "aurumos-share-v1"
local MARKET_PROTOCOL = "aurumos-market-v1"
local UPDATE_PROTOCOL = "aurumos-update-v1"
local TURTLE_PROTOCOL = "aurumos-turtle-v1"
local GAME_PROTOCOL = "aurumos-game-v1"
local INSTALL_PROTOCOL = "aurumos-install-v1"
local SETTINGS_FILE = fs.combine(SYSTEM, "settings.dat")

local unpack = table.unpack or unpack

-- Create system directories
for _, dir in ipairs({DESKTOP, PROGRAMS, SYSTEM, MODULES}) do
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

-- Load activation check
local activation = dofile(fs.combine(SYSTEM, "activation.lua"))
if not activation.isActivated(ROOT, VERSION) then
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print(OS_NAME .. " is not activated on this computer.")
    print("Run install.lua and activate version " .. VERSION .. ".")
    return
end

if not window or not window.create then
    print("This ComputerCraft build does not have the window API.")
    return
end

-- Settings structure
local uiSettings = {
    theme = "modern",
    iconSize = "medium",
    textScale = "native",
    password = "",
    marketServer = "",
    autoUpdate = "on",
    monitorSide = "",
    speakerSide = "",
    volume = "60",
    graphsEnabled = "on"
}

local function loadSettings()
    if not fs.exists(SETTINGS_FILE) then return end
    local handle = fs.open(SETTINGS_FILE, "r")
    if not handle then return end
    local text = handle.readAll()
    handle.close()
    for line in tostring(text or ""):gmatch("[^\r\n]+") do
        local key, value = line:match("^([%w_]+)=(.*)$")
        if key and uiSettings[key] ~= nil then
            uiSettings[key] = value
        end
    end
end

local function saveSettings()
    if not fs.exists(SYSTEM) then fs.makeDir(SYSTEM) end
    local handle = fs.open(SETTINGS_FILE, "w")
    for k, v in pairs(uiSettings) do
        handle.writeLine(k .. "=" .. tostring(v))
    end
    handle.close()
end

loadSettings()

-- Monitor redirection
if uiSettings.monitorSide ~= "" and peripheral and peripheral.getType(uiSettings.monitorSide) == "monitor" then
    local monitor = peripheral.wrap(uiSettings.monitorSide)
    if monitor then pcall(term.redirect, monitor) end
end

local parentTerm = term.current and term.current() or term
if uiSettings.textScale ~= "native" and parentTerm.setTextScale then
    pcall(parentTerm.setTextScale, tonumber(uiSettings.textScale))
end

local W, H = term.getSize()
local taskbarY = H

-- Modern theme palette
local palette = {
    desktop = colors.cyan,
    desktopText = colors.white,
    taskbar = colors.gray,
    taskbarText = colors.white,
    taskbarActive = colors.blue,
    window = colors.black,
    title = colors.blue,
    titleInactive = colors.gray,
    titleText = colors.white,
    selected = colors.blue,
    panel = colors.lightGray,
    panelText = colors.black,
    danger = colors.red,
    success = colors.green,
    warning = colors.yellow
}

local function bootSplash()
    term.setCursorBlink(false)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    local title = "Starting AurumOS 1.0.5"
    local hint = "Press B for BIOS"
    local barWidth = math.max(12, math.min(30, W - 6))
    local x = math.max(1, math.floor((W - barWidth) / 2) + 1)
    local y = math.max(2, math.floor(H / 2))
    term.setCursorPos(math.max(1, math.floor((W - #title) / 2) + 1), y - 2)
    term.write(title)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(math.max(1, math.floor((W - #hint) / 2) + 1), y + 4)
    term.write(hint)
    for step = 1, 20 do
        local filled = math.floor((step / 20) * barWidth)
        term.setCursorPos(x, y)
        term.setBackgroundColor(colors.gray)
        term.write(string.rep(" ", barWidth))
        term.setCursorPos(x, y)
        term.setBackgroundColor(colors.blue)
        term.write(string.rep(" ", filled))
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.lightGray)
        term.setCursorPos(x, y + 2)
        term.write(string.rep(" ", barWidth))
        term.setCursorPos(x, y + 2)
        term.write("Loading " .. tostring(math.floor(step * 5)) .. "%")
        local timer = os.startTimer(0.1)
        while true do
            local event = { os.pullEventRaw() }
            if event[1] == "timer" and event[2] == timer then break
            elseif event[1] == "key" and event[2] == keys.b then return "bios" end
        end
    end
end

local function speakerVolume()
    local value = tonumber(uiSettings.volume or "60") or 60
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    return value / 100
end

local function findSpeaker()
    if peripheral and uiSettings.speakerSide ~= "" and peripheral.getType(uiSettings.speakerSide) == "speaker" then
        return peripheral.wrap(uiSettings.speakerSide), uiSettings.speakerSide
    end
    if peripheral and peripheral.find then
        local speaker = peripheral.find("speaker")
        if speaker then return speaker, "auto" end
    end
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral and peripheral.getType(side) == "speaker" then
            return peripheral.wrap(side), side
        end
    end
    return nil, nil
end

local function playUiSound(kind)
    local speaker = findSpeaker()
    if not speaker then return end
    local vol = speakerVolume() * 2
    if vol <= 0 then return end
    if kind == "boot" then
        pcall(speaker.playNote, "bell", vol, 12)
        sleep(0.08)
        pcall(speaker.playNote, "bell", vol, 16)
    elseif kind == "click" then
        pcall(speaker.playNote, "pling", vol, 10)
    elseif kind == "warn" then
        pcall(speaker.playNote, "bass", vol, 4)
    elseif kind == "success" then
        pcall(speaker.playNote, "bell", vol, 14)
    end
end

local function loginPrompt()
    local expected = tostring(uiSettings.password or "")
    if expected == "" then return end
    while true do
        term.setCursorBlink(false)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        local title = "AurumOS Login"
        local prompt = "Password: "
        local y = math.max(2, math.floor(H / 2))
        term.setCursorPos(math.max(1, math.floor((W - #title) / 2) + 1), y - 2)
        term.write(title)
        term.setCursorPos(math.max(1, math.floor((W - #prompt - 12) / 2) + 1), y)
        term.write(prompt)
        term.setCursorBlink(true)
        local entered = read("*")
        term.setCursorBlink(false)
        if entered == expected then return end
        term.setTextColor(colors.red)
        term.setCursorPos(math.max(1, math.floor((W - 15) / 2) + 1), y + 2)
        term.write("Wrong password.")
        sleep(1)
    end
end

local function biosConsole()
    while true do
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        print("AurumOS 1.0.5 BIOS / Boot Tools")
        print("")
        print("1. Continue AurumOS")
        print("2. Reinstall AurumOS")
        print("3. Boot another OS/program")
        print("4. Native ComputerCraft shell")
        print("5. Download from network")
        print("6. Shutdown")
        print("")
        write("Select: ")
        local choice = read()
        if choice == "1" or choice == "" then
            return "continue"
        elseif choice == "2" then
            local installer = fs.exists("/install.lua") and "/install.lua" or "install.lua"
            if shell and shell.run and fs.exists(installer) then
                shell.run(installer)
            else
                print("install.lua not found.")
                sleep(1.5)
            end
        elseif choice == "3" then
            write("Path: ")
            local path = read()
            if path and path ~= "" and shell and shell.run then
                shell.run(path)
            end
        elseif choice == "4" then
            return "shell"
        elseif choice == "5" then
            print("Searching for installation server...")
            if rednet and peripheral then
                for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
                    if peripheral.getType(side) == "modem" then
                        pcall(rednet.open, side)
                        break
                    end
                end
                rednet.broadcast({action = "discover_installer"}, INSTALL_PROTOCOL)
                local timer = os.startTimer(3)
                while true do
                    local event, param1, param2, param3 = os.pullEvent()
                    if event == "rednet_message" and param3 == INSTALL_PROTOCOL then
                        if type(param2) == "table" and param2.action == "installer_ready" then
                            print("Found installer on computer " .. param1)
                            sleep(1)
                            return "continue"
                        end
                    elseif event == "timer" and param1 == timer then
                        print("No installer found.")
                        break
                    end
                end
            end
        elseif choice == "6" then
            os.shutdown()
        end
    end
end

-- Desktop and window management
local windows = {}
local nextWindowId = 1
local focusedId = nil
local desktopIcons = {}
local selectedIcon = nil
local processes = {} -- Process manager
local nextProcessId = 1
local exitToShell = false

local function min(a, b)
    return a < b and a or b
end

local function max(a, b)
    return a > b and a or b
end

local function clamp(value, low, high)
    if value < low then return low
    elseif value > high then return high
    else return value end
end

local function shorten(text, width)
    text = tostring(text or "")
    if width <= 0 then return "" end
    if #text <= width then return text end
    if width <= 2 then return text:sub(1, width) end
    return text:sub(1, width - 1) .. "."
end

local function writeAt(x, y, text, fg, bg)
    if y < 1 or y > H or x > W then return end
    text = tostring(text or "")
    if x < 1 then
        text = text:sub(2 - x)
        x = 1
    end
    if #text > W - x + 1 then
        text = text:sub(1, W - x + 1)
    end
    if bg then term.setBackgroundColor(bg) end
    if fg then term.setTextColor(fg) end
    term.setCursorPos(x, y)
    term.write(text)
end

local function fill(x, y, width, height, bg)
    if width <= 0 or height <= 0 then return end
    local fromY = max(1, y)
    local toY = min(H, y + height - 1)
    local fromX = max(1, x)
    local toX = min(W, x + width - 1)
    if fromX > toX then return end
    term.setBackgroundColor(bg)
    local line = string.rep(" ", toX - fromX + 1)
    for yy = fromY, toY do
        term.setCursorPos(fromX, yy)
        term.write(line)
    end
end

local function normalizePath(path, base)
    path = tostring(path or "")
    base = tostring(base or "/")
    local full
    if path == "" then
        full = base
    elseif path:sub(1, 1) == "/" then
        full = path
    else
        if base == "/" then
            full = "/" .. path
        else
            full = base .. "/" .. path
        end
    end
    local parts = {}
    for part in full:gmatch("[^/]+") do
        if part == ".." then
            parts[#parts] = nil
        elseif part ~= "." and part ~= "" then
            parts[#parts + 1] = part
        end
    end
    return "/" .. table.concat(parts, "/")
end

local function readFile(path)
    if not fs.exists(path) or fs.isDir(path) then return nil end
    local handle = fs.open(path, "r")
    if not handle then return nil end
    local text = handle.readAll()
    handle.close()
    return text
end

local function writeFile(path, text)
    local dir = fs.getDir(path)
    if dir and dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    local handle = fs.open(path, "w")
    if not handle then return false end
    handle.write(tostring(text or ""))
    handle.close()
    return true
end

local function findWindow(id)
    for index, win in ipairs(windows) do
        if win.id == id then
            return win, index
        end
    end
    return nil
end

local function topVisibleWindow()
    for i = #windows, 1, -1 do
        if not windows[i].minimized then
            return windows[i]
        end
    end
    return nil
end

local function focusWindow(id)
    local win, index = findWindow(id)
    if not win then return end
    win.minimized = false
    table.remove(windows, index)
    table.insert(windows, win)
    focusedId = id
end

local function closeWindow(id)
    local win, index = findWindow(id)
    if not win then return end
    win.term.setVisible(false)
    table.remove(windows, index)
    if focusedId == id then
        local top = topVisibleWindow()
        focusedId = top and top.id or nil
    end
end

local function minimizeWindow(id)
    local win = findWindow(id)
    if not win then return end
    win.minimized = true
    win.term.setVisible(false)
    if focusedId == id then
        local top = topVisibleWindow()
        focusedId = top and top.id or nil
    end
end

local function drawCrash(win, err)
    win.dead = true
    local t = win.term
    local w, h = t.getSize()
    t.setBackgroundColor(colors.red)
    t.setTextColor(colors.white)
    t.clear()
    t.setCursorPos(1, 1)
    t.write(shorten("CRASH", w))
    t.setCursorPos(1, 2)
    t.write(shorten(tostring(err or "Unknown error"), w))
    t.setCursorPos(1, h)
    t.write(shorten("Press X to close", w))
end

local function makeContext(win)
    local ctx = {}
    ctx.term = win.term
    ctx.window = win
    ctx.root = ROOT
    ctx.desktop = DESKTOP
    ctx.programs = PROGRAMS
    ctx.version = VERSION
    ctx.processId = nextProcessId
    
    function ctx.pullEvent(filter)
        return coroutine.yield(filter)
    end
    
    function ctx.close()
        win.closeRequested = true
    end
    
    function ctx.exitToShell()
        exitToShell = true
        win.closeRequested = true
    end
    
    return ctx
end

local function resumeWindow(win, event)
    if not win or win.dead or win.closeRequested then return end
    if win.filter and event and win.filter ~= event[1] and event[1] ~= "terminate" then return end
    
    local ok, filterOrErr
    if event then
        ok, filterOrErr = coroutine.resume(win.co, unpack(event))
    else
        ok, filterOrErr = coroutine.resume(win.co)
    end
    
    if not ok then
        drawCrash(win, filterOrErr)
        return
    end
    
    if coroutine.status(win.co) == "dead" then
        win.dead = true
    else
        win.filter = filterOrErr
    end
    
    if win.closeRequested then
        closeWindow(win.id)
    end
end

local function createWindow(title, width, height, runner)
    local win = {
        id = nextWindowId,
        title = tostring(title or "Window"),
        x = 4 + (#windows % 4) * 3,
        y = 2 + (#windows % 4) * 2,
        w = width or min(42, max(24, W - 6)),
        h = height or min(15, max(7, H - 4)),
        minimized = false,
        dead = false,
        closeRequested = false,
        filter = nil,
        processId = nextProcessId
    }
    nextWindowId = nextWindowId + 1
    nextProcessId = nextProcessId + 1
    
    win.w = clamp(win.w, 18, W)
    win.h = clamp(win.h, 6, max(6, H - 1))
    win.x = clamp(win.x, 1, W - win.w + 1)
    win.y = clamp(win.y, 1, H - win.h)
    
    local cw = max(8, win.w)
    local ch = max(3, win.h - 1)
    win.term = window.create(parentTerm, win.x, win.y + 1, cw, ch, false)
    
    win.co = coroutine.create(function()
        local ctx = makeContext(win)
        runner(ctx)
        if not win.closeRequested then
            local t = ctx.term
            local w, h = t.getSize()
            if h >= 2 then
                t.setCursorPos(1, h)
                t.setTextColor(colors.lightGray)
                t.setBackgroundColor(colors.black)
                t.write(shorten("Press any key to close", w))
            end
            while true do
                local event = { ctx.pullEvent() }
                if event[1] == "key" or event[1] == "mouse_click" then
                    ctx.close()
                    break
                end
            end
        end
    end)
    
    table.insert(windows, win)
    focusWindow(win.id)
    resumeWindow(win)
    return win
end

-- Load terminal and game applications
local launchTerminal
local launchGames
local launchProcessManager

local bios_result = bootSplash()
if bios_result == "bios" then
    biosConsole()
    return
end

playUiSound("boot")
loginPrompt()

-- Main event loop
local running = true
while running do
    local event = {os.pullEvent()}
    
    if event[1] == "terminate" then
        break
    elseif event[1] == "key" then
        if event[2] == keys.f1 then
            createWindow("Process Manager", 50, 15, function(ctx)
                local t = ctx.term
                t.setBackgroundColor(colors.black)
                t.setTextColor(colors.white)
                t.clear()
                t.setCursorPos(1, 1)
                t.write("=== Process Manager ===")
                t.setCursorPos(1, 2)
                t.write("Active Windows: " .. #windows)
                t.setCursorPos(1, 3)
                t.write("")
                local y = 4
                for i, win in ipairs(windows) do
                    if y < t.getSize() - 1 then
                        t.setCursorPos(1, y)
                        t.write("[" .. win.id .. "] " .. shorten(win.title, t.getSize() - 10))
                        y = y + 1
                    end
                end
            end)
        end
    end
    
    for i = 1, #windows do
        if event[1] == "mouse_click" and event[2] and event[3] then
            local x, y = event[2], event[3]
            if i <= #windows and not windows[i].minimized then
                local win = windows[i]
                if y == win.y then
                    if x >= win.x and x < win.x + win.w - 2 then
                        focusWindow(win.id)
                    elseif x == win.x + win.w - 1 then
                        minimizeWindow(win.id)
                    elseif x == win.x + win.w then
                        closeWindow(win.id)
                    end
                end
            end
        end
    end
    
    for i = 1, #windows do
        if event[1] == "char" or event[1] == "key" or event[1] == "mouse_click" or event[1] == "timer" then
            resumeWindow(windows[i], event)
        end
    end
end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print("Thank you for using AurumOS 1.0.5")
sleep(1)
