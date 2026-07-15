local OS_NAME = "AurumOS"
local VERSION = "1.0.4"
local ROOT = "/x32"
local DESKTOP = fs.combine(ROOT, "Desktop")
local PROGRAMS = fs.combine(ROOT, "Programs")
local SYSTEM = fs.combine(ROOT, "system")
local SHARE_PROTOCOL = "aurumos-share-v1"
local MARKET_PROTOCOL = "aurumos-market-v1"
local UPDATE_PROTOCOL = "aurumos-update-v1"
local TURTLE_PROTOCOL = "aurumos-turtle-v1"
local GAME_PROTOCOL = "aurumos-game-v1"
local SETTINGS_FILE = fs.combine(SYSTEM, "settings.dat")

local unpack = table.unpack or unpack

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

if not fs.exists(DESKTOP) then
    fs.makeDir(DESKTOP)
end
if not fs.exists(PROGRAMS) then
    fs.makeDir(PROGRAMS)
end

local uiSettings = {
    gradient = "blue",
    iconSize = "small",
    textScale = "native",
    password = "",
    marketServer = "",
    autoUpdate = "on",
    monitorSide = "",
    speakerSide = "",
    volume = "60"
}

local function loadSettings()
    if not fs.exists(SETTINGS_FILE) then
        return
    end
    local handle = fs.open(SETTINGS_FILE, "r")
    if not handle then
        return
    end
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
    if not fs.exists(SYSTEM) then
        fs.makeDir(SYSTEM)
    end
    local handle = fs.open(SETTINGS_FILE, "w")
    handle.writeLine("gradient=" .. tostring(uiSettings.gradient))
    handle.writeLine("iconSize=" .. tostring(uiSettings.iconSize))
    handle.writeLine("textScale=" .. tostring(uiSettings.textScale))
    handle.writeLine("password=" .. tostring(uiSettings.password or ""))
    handle.writeLine("marketServer=" .. tostring(uiSettings.marketServer or ""))
    handle.writeLine("autoUpdate=" .. tostring(uiSettings.autoUpdate or "on"))
    handle.writeLine("monitorSide=" .. tostring(uiSettings.monitorSide or ""))
    handle.writeLine("speakerSide=" .. tostring(uiSettings.speakerSide or ""))
    handle.writeLine("volume=" .. tostring(uiSettings.volume or "60"))
    handle.close()
end

loadSettings()

if uiSettings.monitorSide ~= "" and peripheral and peripheral.getType(uiSettings.monitorSide) == "monitor" then
    local monitor = peripheral.wrap(uiSettings.monitorSide)
    if monitor then
        pcall(term.redirect, monitor)
    end
end

local parentTerm = term.current and term.current() or term
if uiSettings.textScale ~= "native" and parentTerm.setTextScale then
    pcall(parentTerm.setTextScale, tonumber(uiSettings.textScale))
end
local W, H = term.getSize()
local taskbarY = H

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
    danger = colors.red
}

local function bootSplash()
    term.setCursorBlink(false)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    local title = "Starting AurumOS"
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
        local timer = os.startTimer(0.15)
        while true do
            local event = { os.pullEventRaw() }
            if event[1] == "timer" and event[2] == timer then
                break
            elseif event[1] == "key" and event[2] == keys.b then
                return "bios"
            end
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
        if speaker then
            return speaker, "auto"
        end
    end
    for _, side in ipairs({ "top", "bottom", "left", "right", "front", "back" }) do
        if peripheral and peripheral.getType(side) == "speaker" then
            return peripheral.wrap(side), side
        end
    end
    return nil, nil
end

local function playUiSound(kind)
    local speaker = findSpeaker()
    if not speaker then
        return
    end
    local vol = speakerVolume() * 2
    if vol <= 0 then
        return
    end
    if kind == "boot" then
        pcall(speaker.playNote, "bell", vol, 12)
        sleep(0.08)
        pcall(speaker.playNote, "bell", vol, 16)
    elseif kind == "click" then
        pcall(speaker.playNote, "pling", vol, 10)
    elseif kind == "warn" then
        pcall(speaker.playNote, "bass", vol, 4)
    elseif kind == "doom" then
        pcall(speaker.playNote, "basedrum", vol, 5)
        pcall(speaker.playNote, "snare", vol, 8)
    end
end

local function loginPrompt()
    local expected = tostring(uiSettings.password or "")
    if expected == "" then
        return
    end

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
        if entered == expected then
            return
        end
        term.setTextColor(colors.red)
        term.setCursorPos(math.max(1, math.floor((W - 15) / 2) + 1), y + 2)
        term.write("Wrong password.")
        sleep(1)
    end
end

local function minecraftClockText()
    local ok, timeText = pcall(function()
        return textutils.formatTime(os.time(), true)
    end)
    if not ok then
        timeText = tostring(math.floor(os.time()))
    end
    return "Day " .. tostring(os.day()) .. " " .. timeText
end

local function storageText()
    local free = tonumber(fs.getFreeSpace and fs.getFreeSpace("/") or 0) or 0
    local capacity = tonumber(fs.getCapacity and fs.getCapacity("/") or nil)
    if capacity and capacity > 0 then
        local used = capacity - free
        local pct = math.floor((used / capacity) * 100)
        return "Disk " .. tostring(pct) .. "%"
    end
    return "Free " .. tostring(math.floor(free / 1024)) .. "K"
end

local function volumeText()
    local value = tonumber(uiSettings.volume or "60") or 60
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    return "Vol[" .. string.rep("|", math.floor(value / 20)) .. string.rep(".", 5 - math.floor(value / 20)) .. "]"
end

local function biosConsole()
    while true do
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        print("AurumOS BIOS / Boot Tools")
        print("")
        print("1. Continue AurumOS")
        print("2. Reinstall AurumOS")
        print("3. Boot another OS/program")
        print("4. Native ComputerCraft shell")
        print("5. Shutdown")
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
            os.shutdown()
        end
    end
end

local windows = {}
local nextWindowId = 1
local focusedId = nil
local desktopIcons = {}
local selectedIcon = nil
local desktopDragIcon = nil
local desktopDragActive = false
local lastIconClick = { path = nil, time = 0 }
local taskRects = {}
local volumeRect = nil
local trashRect = nil
local menuOpen = false
local startTab = "System"
local dragging = nil
local exitToShell = false

local launchPath
local launchFiles
local launchTerminal
local launchShare
local launchCCShell
local launchSettings
local launchCalculator
local launchPaint
local launchSheets
local launchClock
local launchCode
local launchBios
local launchMarket
local launchTurtleRemote
local launchBallistics
local launchEngineeringCalc
local launchAddIcon
local launchMonitor
local launchMixer
local launchDoom
local launchGames

local function min(a, b)
    if a < b then return a end
    return b
end

local function max(a, b)
    if a > b then return a end
    return b
end

local function clamp(value, low, high)
    if high < low then
        return low
    end
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

local function pad(text, width)
    text = tostring(text or "")
    if #text > width then
        return text:sub(1, width)
    end
    return text .. string.rep(" ", width - #text)
end

local function shorten(text, width)
    text = tostring(text or "")
    if width <= 0 then
        return ""
    end
    if #text <= width then
        return text
    end
    if width <= 2 then
        return text:sub(1, width)
    end
    return text:sub(1, width - 1) .. "."
end

local function writeAt(x, y, text, fg, bg)
    if y < 1 or y > H or x > W then
        return
    end
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
    if width <= 0 or height <= 0 then
        return
    end
    local fromY = max(1, y)
    local toY = min(H, y + height - 1)
    local fromX = max(1, x)
    local toX = min(W, x + width - 1)
    if fromX > toX then
        return
    end
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

local function parentPath(path)
    path = normalizePath(path)
    if path == "/" then
        return "/"
    end
    local dir = fs.getDir(path)
    if not dir or dir == "" then
        return "/"
    end
    if dir:sub(1, 1) ~= "/" then
        dir = "/" .. dir
    end
    return normalizePath(dir)
end

local function extension(path)
    local name = fs.getName(path or "")
    return (name:match("%.([^%.]+)$") or ""):lower()
end

local function readFile(path)
    if not fs.exists(path) or fs.isDir(path) then
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

local function writeEmptyFile(path)
    local handle = fs.open(path, "w")
    if handle then
        handle.close()
    end
end

local function ensureParent(path)
    local dir = fs.getDir(path)
    if dir and dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

local function writeFile(path, text)
    ensureParent(path)
    local handle = fs.open(path, "w")
    if not handle then
        return false, "Cannot open file."
    end
    handle.write(tostring(text or ""))
    handle.close()
    return true
end

local function copyName(path)
    local name = fs.getName(path)
    local base, ext = name:match("^(.*)%.([^%.]+)$")
    if base and ext then
        return base .. "_copy." .. ext
    end
    return name .. "_copy"
end

local function copyPath(source, target)
    if not fs.exists(source) then
        return false, "Source not found."
    end
    if fs.exists(target) then
        return false, "Target already exists."
    end

    if fs.isDir(source) then
        fs.makeDir(target)
        for _, name in ipairs(fs.list(source)) do
            local ok, err = copyPath(fs.combine(source, name), fs.combine(target, name))
            if not ok then
                return false, err
            end
        end
        return true
    end

    ensureParent(target)
    local ok, err = pcall(fs.copy, source, target)
    if not ok then
        return false, tostring(err)
    end
    return true
end

local function movePath(source, target)
    if not fs.exists(source) then
        return false, "Source not found."
    end
    if fs.exists(target) then
        return false, "Target already exists."
    end
    ensureParent(target)
    local ok, err = pcall(fs.move, source, target)
    if ok then
        return true
    end
    return false, tostring(err)
end

local function modemSides()
    if redstone and redstone.getSides then
        return redstone.getSides()
    end
    return { "top", "bottom", "left", "right", "front", "back" }
end

local function openRednetModem()
    if not rednet or not peripheral then
        return false, "RedNet is not available."
    end
    for _, side in ipairs(modemSides()) do
        if peripheral.getType(side) == "modem" then
            if rednet.isOpen and rednet.isOpen(side) then
                return true, side
            end
            local ok, err = pcall(rednet.open, side)
            if ok then
                return true, side
            end
            return false, tostring(err)
        end
    end
    return false, "No modem found."
end

local function safeFileName(name)
    name = tostring(name or "shared.txt")
    name = name:gsub("[/\\:%*%?\"<>|]", "_")
    if name == "" then
        return "shared.txt"
    end
    return name
end

local function uniquePath(path)
    if not fs.exists(path) then
        return path
    end
    local dir = fs.getDir(path)
    local name = fs.getName(path)
    local base, ext = name:match("^(.*)%.([^%.]+)$")
    base = base or name
    for i = 2, 99 do
        local candidate = fs.combine(dir, base .. "_" .. tostring(i) .. (ext and ("." .. ext) or ""))
        if not fs.exists(candidate) then
            return candidate
        end
    end
    return fs.combine(dir, base .. "_" .. tostring(os.clock()) .. (ext and ("." .. ext) or ""))
end

local function parseLink(path)
    local text = readFile(path)
    local data = {}
    if not text then
        return data
    end
    for line in text:gmatch("[^\r\n]+") do
        local k, v = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
        if k then
            data[k:lower()] = v
        end
    end
    return data
end

local function listSorted(path)
    local entries = {}
    if not fs.exists(path) or not fs.isDir(path) then
        return entries
    end
    for _, name in ipairs(fs.list(path)) do
        local full = fs.combine(path, name)
        entries[#entries + 1] = {
            name = name,
            path = full,
            dir = fs.isDir(full)
        }
    end
    table.sort(entries, function(a, b)
        if a.dir ~= b.dir then
            return a.dir
        end
        return a.name:lower() < b.name:lower()
    end)
    return entries
end

local function clearClient(termObj, bg)
    termObj.setBackgroundColor(bg or colors.black)
    termObj.setTextColor(colors.white)
    termObj.clear()
    termObj.setCursorPos(1, 1)
end

local function clientSizeFor(win)
    return max(8, win.w), max(3, win.h - 1)
end

local function clampWindow(win)
    win.w = clamp(win.w, 18, W)
    win.h = clamp(win.h, 6, max(6, H - 1))
    win.x = clamp(win.x, 1, W - win.w + 1)
    win.y = clamp(win.y, 1, H - win.h)
end

local function repositionClient(win)
    clampWindow(win)
    local cw, ch = clientSizeFor(win)
    win.term.reposition(win.x, win.y + 1, cw, ch)
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
    if not win then
        return
    end
    win.minimized = false
    table.remove(windows, index)
    table.insert(windows, win)
    focusedId = id
end

local function closeWindow(id)
    local win, index = findWindow(id)
    if not win then
        return
    end
    win.term.setVisible(false)
    table.remove(windows, index)
    if focusedId == id then
        local top = topVisibleWindow()
        focusedId = top and top.id or nil
    end
end

local function minimizeWindow(id)
    local win = findWindow(id)
    if not win then
        return
    end
    win.minimized = true
    win.term.setVisible(false)
    if focusedId == id then
        local top = topVisibleWindow()
        focusedId = top and top.id or nil
    end
end

local function drawClientMessage(win, title, lines, bg)
    local t = win.term
    local w, h = t.getSize()
    t.setBackgroundColor(bg or colors.black)
    t.setTextColor(colors.white)
    t.clear()
    t.setCursorPos(1, 1)
    t.write(shorten(title, w))
    for i, line in ipairs(lines or {}) do
        if i + 1 <= h then
            t.setCursorPos(1, i + 1)
            t.write(shorten(line, w))
        end
    end
end

local function drawCrash(win, err)
    win.dead = true
    drawClientMessage(win, "Program stopped", {
        tostring(err or "Unknown error"),
        "",
        "Use X to close this window."
    }, colors.red)
end

local function makeContext(win)
    local ctx = {}
    ctx.term = win.term
    ctx.window = win
    ctx.root = ROOT
    ctx.desktop = DESKTOP
    ctx.programs = PROGRAMS
    ctx.version = VERSION

    function ctx.pullEvent(filter)
        return coroutine.yield(filter)
    end

    function ctx.close()
        win.closeRequested = true
    end

    function ctx.openPath(path)
        if launchPath then
            launchPath(path)
        end
    end

    function ctx.openFiles(path)
        if launchFiles then
            launchFiles(path)
        end
    end

    function ctx.exitToShell()
        exitToShell = true
        win.closeRequested = true
    end

    return ctx
end

local function waitForClose(ctx)
    local t = ctx.term
    local w, h = t.getSize()
    if h >= 2 then
        t.setCursorPos(1, h)
        t.setTextColor(colors.lightGray)
        t.setBackgroundColor(colors.black)
        t.write(shorten("Finished. Press any key or click to close.", w))
    end
    while true do
        local event = { ctx.pullEvent() }
        if event[1] == "key" or event[1] == "mouse_click" or event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function resumeWindow(win, event)
    if not win or win.dead or win.closeRequested then
        return
    end
    if win.filter and event and win.filter ~= event[1] and event[1] ~= "terminate" then
        return
    end

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
        filter = nil
    }
    nextWindowId = nextWindowId + 1
    clampWindow(win)
    local cw, ch = clientSizeFor(win)
    win.term = window.create(parentTerm, win.x, win.y + 1, cw, ch, false)
    win.co = coroutine.create(function()
        local ctx = makeContext(win)
        runner(ctx)
        if not win.closeRequested then
            waitForClose(ctx)
        end
    end)

    table.insert(windows, win)
    focusWindow(win.id)
    resumeWindow(win)
    return win
end

local function writeTermLine(t, text)
    local w, h = t.getSize()
    local x, y = t.getCursorPos()
    text = tostring(text or "")
    for i = 1, #text do
        local ch = text:sub(i, i)
        if ch == "\n" then
            x, y = t.getCursorPos()
            if y >= h then
                t.scroll(1)
                t.setCursorPos(1, h)
            else
                t.setCursorPos(1, y + 1)
            end
        else
            x, y = t.getCursorPos()
            if x > w then
                if y >= h then
                    t.scroll(1)
                    t.setCursorPos(1, h)
                else
                    t.setCursorPos(1, y + 1)
                end
            end
            t.write(ch)
        end
    end
end

local function makeProgramEnv(ctx, path)
    local t = ctx.term
    local cwd = parentPath(path)

    local env = {}
    env._G = env
    env.term = t
    env.colors = colors
    env.colours = colours or colors
    env.keys = keys
    env.fs = fs
    env.peripheral = peripheral
    env.redstone = redstone
    env.rs = rs
    env.textutils = textutils
    env.paintutils = paintutils
    env.http = http
    env.gps = gps
    env.rednet = rednet
    env.disk = disk
    env.settings = settings

    local osProxy = {}
    for k, v in pairs(os) do
        osProxy[k] = v
    end
    function osProxy.pullEvent(filter)
        return ctx.pullEvent(filter)
    end
    function osProxy.pullEventRaw(filter)
        return ctx.pullEvent(filter)
    end
    env.os = osProxy

    function env.sleep(seconds)
        local timer = os.startTimer(tonumber(seconds) or 0)
        while true do
            local event = { ctx.pullEvent("timer") }
            if event[2] == timer then
                return
            end
        end
    end

    function env.write(text)
        writeTermLine(t, text)
    end

    function env.print(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[#parts + 1] = tostring(select(i, ...))
        end
        writeTermLine(t, table.concat(parts, "    "))
        writeTermLine(t, "\n")
    end

    function env.read(replaceChar, history, completeFn, default)
        local line = tostring(default or "")
        local startX, startY = t.getCursorPos()
        local w = t.getSize()

        local function render()
            t.setCursorPos(startX, startY)
            local visible = replaceChar and string.rep(tostring(replaceChar), #line) or line
            t.write(shorten(visible, w - startX + 1))
            local x = startX + #visible
            if x <= w then
                t.write(string.rep(" ", w - x + 1))
            end
            t.setCursorPos(min(w, startX + #visible), startY)
        end

        render()
        while true do
            local event = { ctx.pullEvent() }
            if event[1] == "char" then
                line = line .. event[2]
                render()
            elseif event[1] == "key" then
                if event[2] == keys.enter then
                    writeTermLine(t, "\n")
                    return line
                elseif event[2] == keys.backspace then
                    line = line:sub(1, #line - 1)
                    render()
                end
            elseif event[1] == "paste" then
                line = line .. tostring(event[2] or "")
                render()
            end
        end
    end

    local shellProxy = {}
    function shellProxy.dir()
        return cwd
    end
    function shellProxy.setDir(pathValue)
        cwd = normalizePath(pathValue, cwd)
    end
    function shellProxy.resolve(pathValue)
        return normalizePath(pathValue, cwd)
    end
    function shellProxy.getRunningProgram()
        return path
    end
    function shellProxy.resolveProgram(name)
        local candidates = {
            normalizePath(name, cwd),
            normalizePath(name .. ".lua", cwd),
            normalizePath(name, PROGRAMS),
            normalizePath(name .. ".lua", PROGRAMS),
            normalizePath(name, "/rom/programs"),
            normalizePath(name .. ".lua", "/rom/programs")
        }
        for _, candidate in ipairs(candidates) do
            if fs.exists(candidate) and not fs.isDir(candidate) then
                return candidate
            end
        end
        return nil
    end
    function shellProxy.run(name, ...)
        local resolved = shellProxy.resolveProgram(name) or shellProxy.resolve(name)
        if fs.exists(resolved) then
            ctx.openPath(resolved)
            return true
        end
        env.print("No such program: " .. tostring(name))
        return false
    end
    env.shell = shellProxy

    env.arg = { path }
    setmetatable(env, { __index = _G })
    return env
end

local function loadWithEnv(path, env)
    local fn, err
    if setfenv then
        fn, err = loadfile(path)
        if fn then
            setfenv(fn, env)
        end
    else
        local ok, result, loadErr = pcall(loadfile, path, "t", env)
        if ok then
            fn, err = result, loadErr
        else
            ok, result, loadErr = pcall(loadfile, path, env)
            if ok then
                fn, err = result, loadErr
            else
                err = result
            end
        end
    end
    return fn, err
end

local function programApp(ctx, path)
    clearClient(ctx.term, colors.black)
    local env = makeProgramEnv(ctx, path)
    local fn, err = loadWithEnv(path, env)
    if not fn then
        error(err or "Cannot load program", 0)
    end
    fn()
end

local function promptLine(ctx, prompt, default)
    local t = ctx.term
    local w, h = t.getSize()
    local line = tostring(default or "")

    local function render()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.setCursorPos(1, h)
        t.write(string.rep(" ", w))
        t.setCursorPos(1, h)
        t.write(shorten(prompt .. line, w))
    end

    render()
    while true do
        local event = { ctx.pullEvent() }
        if event[1] == "char" then
            line = line .. event[2]
            render()
        elseif event[1] == "paste" then
            line = line .. tostring(event[2] or "")
            render()
        elseif event[1] == "key" then
            if event[2] == keys.enter then
                return line
            elseif event[2] == keys.backspace then
                line = line:sub(1, #line - 1)
                render()
            elseif event[2] == keys.escape then
                return nil
            end
        end
    end
end

local function drawRows(t, entries, selected, scroll)
    local w, h = t.getSize()
    local rows = max(1, h - 3)
    for row = 1, rows do
        local entry = entries[scroll + row]
        local y = row + 2
        t.setCursorPos(1, y)
        if entry and selected == entry.path then
            t.setBackgroundColor(colors.blue)
            t.setTextColor(colors.white)
        else
            t.setBackgroundColor(colors.black)
            t.setTextColor(colors.white)
        end
        t.write(string.rep(" ", w))
        t.setCursorPos(1, y)
        if entry then
            local prefix = entry.dir and "[D] " or "    "
            local suffix = entry.dir and "" or ("  " .. tostring(fs.getSize(entry.path)) .. "b")
            t.write(shorten(prefix .. entry.name .. suffix, w))
        end
    end
end

local function filesApp(ctx, startDir)
    local t = ctx.term
    local path = normalizePath(startDir or "/")
    local selected = nil
    local scroll = 0
    local entries = {}
    local lastClick = { path = nil, time = 0 }
    local status = "Ready."
    local dragFile = nil
    local dragActive = false

    local function refresh()
        if not fs.exists(path) or not fs.isDir(path) then
            path = "/"
        end
        entries = listSorted(path)
        if selected and not fs.exists(selected) then
            selected = nil
        end
        scroll = clamp(scroll, 0, max(0, #entries - 1))
    end

    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()

        t.setBackgroundColor(colors.lightGray)
        t.setTextColor(colors.black)
        t.setCursorPos(1, 1)
        t.write(pad("[Up] [New] [Del] [Copy] [Move]", w))

        t.setBackgroundColor(colors.gray)
        t.setTextColor(colors.white)
        t.setCursorPos(1, 2)
        t.write(pad(shorten(path, w), w))

        drawRows(t, entries, selected, scroll)

        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.lightGray)
        t.setCursorPos(1, h)
        local hint = status ~= "" and status or "Enter/open  Backspace/up"
        t.write(shorten(hint, w))
    end

    local function openSelected()
        if not selected then
            return
        end
        if fs.isDir(selected) then
            path = normalizePath(selected)
            selected = nil
            scroll = 0
        else
            ctx.openPath(selected)
        end
    end

    local function newItem()
        local name = promptLine(ctx, "New file or folder/: ")
        if not name or name == "" then
            return
        end
        local isFolder = name:sub(-1) == "/"
        if isFolder then
            name = name:sub(1, #name - 1)
        end
        local target = normalizePath(name, path)
        if fs.exists(target) then
            status = "Target already exists."
            return
        end
        local ok, err
        if isFolder then
            ok, err = pcall(fs.makeDir, target)
        else
            ok, err = pcall(writeEmptyFile, target)
        end
        if ok then
            selected = target
            status = "Created " .. fs.getName(target)
        else
            status = tostring(err)
        end
    end

    local function deleteSelected()
        if not selected then
            return
        end
        local answer = promptLine(ctx, "Delete " .. fs.getName(selected) .. "? y/N: ")
        if answer and (answer:lower() == "y" or answer:lower() == "yes" or answer:lower() == "d" or answer:lower() == "da") then
            local ok, err = pcall(fs.delete, selected)
            if ok then
                status = "Deleted."
                selected = nil
            else
                status = tostring(err)
            end
        end
    end

    local function copySelected(move)
        if not selected then
            return
        end
        local prompt = move and "Move to: " or "Copy to: "
        local defaultName = move and fs.getName(selected) or copyName(selected)
        local target = promptLine(ctx, prompt, normalizePath(defaultName, path))
        if not target or target == "" then
            return
        end
        target = normalizePath(target, path)
        local ok, err
        if move then
            ok, err = movePath(selected, target)
        else
            ok, err = copyPath(selected, target)
        end
        if ok then
            selected = target
            status = move and "Moved." or "Copied."
        else
            status = err or "Operation failed."
        end
    end

    local function buttonAt(x)
        if x >= 1 and x <= 4 then return "up" end
        if x >= 6 and x <= 10 then return "new" end
        if x >= 12 and x <= 16 then return "del" end
        if x >= 18 and x <= 23 then return "copy" end
        if x >= 25 and x <= 30 then return "move" end
        return nil
    end

    while true do
        refresh()
        draw()
        local event = { ctx.pullEvent() }

        if event[1] == "mouse_click" then
            local _, button, x, y = unpack(event)
            if y == 1 then
                local action = buttonAt(x)
                if action == "up" then
                    path = parentPath(path)
                    selected = nil
                    scroll = 0
                elseif action == "new" then
                    newItem()
                elseif action == "del" then
                    deleteSelected()
                elseif action == "copy" then
                    copySelected(false)
                elseif action == "move" then
                    copySelected(true)
                end
            elseif y >= 3 and y < select(2, t.getSize()) then
                local index = scroll + y - 2
                local entry = entries[index]
                if entry then
                    selected = entry.path
                    dragFile = entry.path
                    dragActive = false
                    local now = os.clock()
                    if lastClick.path == entry.path and now - lastClick.time < 0.65 then
                        openSelected()
                        dragFile = nil
                        dragActive = false
                    end
                    lastClick.path = entry.path
                    lastClick.time = now
                end
            end
        elseif event[1] == "mouse_drag" then
            if dragFile and fs.exists(dragFile) then
                dragActive = true
                status = "Dragging " .. fs.getName(dragFile)
            end
        elseif event[1] == "mouse_up" then
            if dragActive and dragFile and fs.exists(dragFile) then
                local _, _, x, y = unpack(event)
                if y >= 3 and y < select(2, t.getSize()) then
                    local index = scroll + y - 2
                    local targetEntry = entries[index]
                    if targetEntry and targetEntry.dir and targetEntry.path ~= dragFile then
                        local target = normalizePath(fs.getName(dragFile), targetEntry.path)
                        local ok, err = movePath(dragFile, target)
                        if ok then
                            selected = target
                            status = "Moved into " .. targetEntry.name
                        else
                            status = err or "Move failed."
                        end
                    else
                        status = "Drop on a folder to move."
                    end
                end
            end
            dragFile = nil
            dragActive = false
        elseif event[1] == "mouse_scroll" then
            local direction = event[2]
            scroll = clamp(scroll + direction, 0, max(0, #entries - 1))
        elseif event[1] == "key" then
            if event[2] == keys.backspace or event[2] == keys.left then
                path = parentPath(path)
                selected = nil
                scroll = 0
            elseif event[2] == keys.enter then
                openSelected()
            elseif event[2] == keys.up then
                if #entries > 0 then
                    local index = 1
                    if selected then
                        for i, entry in ipairs(entries) do
                            if entry.path == selected then index = i - 1 end
                        end
                    end
                    index = clamp(index, 1, #entries)
                    selected = entries[index].path
                    if index <= scroll then scroll = max(0, index - 1) end
                end
            elseif event[2] == keys.down then
                if #entries > 0 then
                    local index = 1
                    if selected then
                        for i, entry in ipairs(entries) do
                            if entry.path == selected then index = i + 1 end
                        end
                    end
                    index = clamp(index, 1, #entries)
                    selected = entries[index].path
                    local visible = select(2, t.getSize()) - 3
                    if index > scroll + visible then scroll = index - visible end
                end
            end
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function textViewerApp(ctx, path)
    local t = ctx.term
    local scroll = 0
    local text = readFile(path) or ""
    local lines = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line
    end

    while true do
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        t.setCursorPos(1, 1)
        t.setBackgroundColor(colors.gray)
        t.write(pad(shorten(path, w), w))
        t.setBackgroundColor(colors.black)
        for row = 2, h do
            local line = lines[scroll + row - 1]
            if line then
                t.setCursorPos(1, row)
                t.write(shorten(line, w))
            end
        end
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_scroll" then
            scroll = clamp(scroll + event[2], 0, max(0, #lines - 1))
        elseif event[1] == "key" then
            if event[2] == keys.up then
                scroll = max(0, scroll - 1)
            elseif event[2] == keys.down then
                scroll = min(max(0, #lines - 1), scroll + 1)
            elseif event[2] == keys.escape or event[2] == keys.backspace then
                ctx.close()
                return
            end
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function terminalApp(ctx)
    local t = ctx.term
    local cwd = "/"
    local lines = { OS_NAME .. " terminal", "Type help for commands." }
    local input = ""

    local function add(line)
        lines[#lines + 1] = tostring(line or "")
        while #lines > 80 do
            table.remove(lines, 1)
        end
    end

    local function redraw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        local first = max(1, #lines - h + 3)
        local row = 1
        for i = first, #lines do
            if row >= h then break end
            t.setCursorPos(1, row)
            t.write(shorten(lines[i], w))
            row = row + 1
        end
        t.setCursorPos(1, h)
        t.setTextColor(colors.lightGray)
        t.write(shorten(cwd .. "> " .. input, w))
    end

    local function split(line)
        local out = {}
        for word in line:gmatch("%S+") do
            out[#out + 1] = word
        end
        return out
    end

    local function runCommand(line)
        add(cwd .. "> " .. line)
        local args = split(line)
        local cmd = (args[1] or ""):lower()
        if cmd == "" then
            return
        elseif cmd == "doom" then
            launchDoom()
        elseif cmd == "help" then
            add("help ls cd pwd open run mkdir rm cp mv clear exit")
        elseif cmd == "pwd" then
            add(cwd)
        elseif cmd == "ls" or cmd == "dir" then
            local target = normalizePath(args[2] or "", cwd)
            for _, entry in ipairs(listSorted(target)) do
                add((entry.dir and "[D] " or "    ") .. entry.name)
            end
        elseif cmd == "cd" then
            local target = normalizePath(args[2] or "/", cwd)
            if fs.exists(target) and fs.isDir(target) then
                cwd = target
            else
                add("No such directory.")
            end
        elseif cmd == "open" or cmd == "run" then
            local target = normalizePath(args[2] or "", cwd)
            if fs.exists(target) then
                ctx.openPath(target)
            else
                add("No such file.")
            end
        elseif cmd == "mkdir" then
            if not args[2] then add("Missing name.") return end
            fs.makeDir(normalizePath(args[2], cwd))
        elseif cmd == "rm" or cmd == "delete" then
            if not args[2] then add("Missing path.") return end
            local target = normalizePath(args[2], cwd)
            if fs.exists(target) then fs.delete(target) else add("No such path.") end
        elseif cmd == "cp" or cmd == "copy" then
            if not args[2] or not args[3] then add("Usage: cp from to") return end
            fs.copy(normalizePath(args[2], cwd), normalizePath(args[3], cwd))
        elseif cmd == "mv" or cmd == "move" then
            if not args[2] or not args[3] then add("Usage: mv from to") return end
            fs.move(normalizePath(args[2], cwd), normalizePath(args[3], cwd))
        elseif cmd == "clear" then
            lines = {}
        elseif cmd == "exit" then
            ctx.close()
            return
        else
            add("Unknown command.")
        end
    end

    while true do
        redraw()
        local event = { ctx.pullEvent() }
        if event[1] == "char" then
            input = input .. event[2]
        elseif event[1] == "paste" then
            input = input .. tostring(event[2] or "")
        elseif event[1] == "key" then
            if event[2] == keys.enter then
                local command = input
                input = ""
                runCommand(command)
            elseif event[2] == keys.backspace then
                input = input:sub(1, #input - 1)
            elseif event[2] == keys.escape then
                ctx.close()
                return
            end
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function shareApp(ctx)
    local t = ctx.term
    local status = "Ready."
    local inbox = {}
    local receiving = false
    local sharedDir = fs.combine(ROOT, "Shared")

    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()

        t.setBackgroundColor(colors.lightGray)
        t.setTextColor(colors.black)
        t.setCursorPos(1, 1)
        t.write(pad("[File] [Text] [Recv] [Inbox]", w))

        t.setBackgroundColor(colors.gray)
        t.setTextColor(colors.white)
        t.setCursorPos(1, 2)
        t.write(pad("RedNet Share  ID " .. tostring(os.getComputerID()), w))

        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.setCursorPos(1, 4)
        t.write(shorten("Status: " .. status, w))

        if receiving then
            t.setCursorPos(1, 6)
            t.setTextColor(colors.lime)
            t.write(shorten("Waiting for " .. SHARE_PROTOCOL .. " messages...", w))
        end

        local row = 8
        t.setTextColor(colors.lightGray)
        for i = max(1, #inbox - 5), #inbox do
            if row <= h - 1 then
                t.setCursorPos(1, row)
                t.write(shorten(inbox[i], w))
                row = row + 1
            end
        end

        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.lightGray)
        t.setCursorPos(1, h)
        t.write(shorten("Esc/Backspace closes. Received files go to /x32/Shared", w))
    end

    local function buttonAt(x)
        if x >= 1 and x <= 6 then return "file" end
        if x >= 8 and x <= 13 then return "text" end
        if x >= 15 and x <= 20 then return "recv" end
        if x >= 22 and x <= 28 then return "inbox" end
        return nil
    end

    local function targetId()
        local idText = promptLine(ctx, "Target ID: ")
        local id = tonumber(idText)
        if not id then
            status = "Target ID must be a number."
            return nil
        end
        return id
    end

    local function sendPacket(id, packet)
        local ok, sideOrErr = openRednetModem()
        if not ok then
            status = sideOrErr
            return
        end
        local sentOk, err = pcall(rednet.send, id, packet, SHARE_PROTOCOL)
        if sentOk then
            status = "Sent to " .. tostring(id) .. "."
        else
            status = tostring(err)
        end
    end

    local function sendFile()
        local id = targetId()
        if not id then return end
        local path = promptLine(ctx, "File path: ", fs.combine(DESKTOP, ""))
        path = normalizePath(path or "")
        if not fs.exists(path) or fs.isDir(path) then
            status = "File not found."
            return
        end
        local text = readFile(path)
        if not text then
            status = "Cannot read file."
            return
        end
        sendPacket(id, {
            app = "AurumOSShare",
            type = "file",
            name = fs.getName(path),
            data = text
        })
    end

    local function sendText()
        local id = targetId()
        if not id then return end
        local text = promptLine(ctx, "Text: ")
        if not text or text == "" then
            status = "Nothing to send."
            return
        end
        sendPacket(id, {
            app = "AurumOSShare",
            type = "text",
            data = text
        })
    end

    local function receivePacket(sender, packet, protocol)
        if protocol ~= SHARE_PROTOCOL then
            return
        end
        if type(packet) ~= "table" or packet.app ~= "AurumOSShare" then
            return
        end

        if packet.type == "file" then
            if not fs.exists(sharedDir) then
                fs.makeDir(sharedDir)
            end
            local name = tostring(sender) .. "_" .. safeFileName(packet.name)
            local path = uniquePath(fs.combine(sharedDir, name))
            local ok, err = writeFile(path, packet.data or "")
            if ok then
                status = "Saved " .. path
                inbox[#inbox + 1] = "file from " .. tostring(sender) .. ": " .. fs.getName(path)
            else
                status = err or "Save failed."
            end
        elseif packet.type == "text" then
            local text = tostring(packet.data or "")
            inbox[#inbox + 1] = "text from " .. tostring(sender) .. ": " .. text
            status = "Text received from " .. tostring(sender) .. "."
        end
    end

    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 then
                local action = buttonAt(x)
                if action == "file" then
                    sendFile()
                elseif action == "text" then
                    sendText()
                elseif action == "recv" then
                    local ok, sideOrErr = openRednetModem()
                    receiving = ok
                    status = ok and ("Listening on " .. sideOrErr .. ".") or sideOrErr
                elseif action == "inbox" then
                    if not fs.exists(sharedDir) then
                        fs.makeDir(sharedDir)
                    end
                    launchFiles(sharedDir)
                end
            end
        elseif event[1] == "rednet_message" then
            receivePacket(event[2], event[3], event[4])
        elseif event[1] == "key" then
            if event[2] == keys.escape or event[2] == keys.backspace then
                ctx.close()
                return
            elseif event[2] == keys.r then
                local ok, sideOrErr = openRednetModem()
                receiving = ok
                status = ok and ("Listening on " .. sideOrErr .. ".") or sideOrErr
            end
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function ccShellApp(ctx)
    local t = ctx.term
    while true do
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        t.setCursorPos(1, 1)
        t.write(shorten("ComputerCraft shell", w))
        t.setCursorPos(1, 3)
        t.write(shorten("[Open] [Cancel]", w))
        t.setCursorPos(1, h)
        t.setTextColor(colors.lightGray)
        t.write(shorten("Open returns AurumOS to the native CC prompt.", w))

        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 3 and x >= 1 and x <= 6 then
                ctx.exitToShell()
                return
            elseif y == 3 and x >= 8 and x <= 15 then
                ctx.close()
                return
            end
        elseif event[1] == "key" then
            if event[2] == keys.enter then
                ctx.exitToShell()
                return
            elseif event[2] == keys.escape or event[2] == keys.backspace then
                ctx.close()
                return
            end
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function applyTextScaleSetting()
    if uiSettings.textScale == "native" then
        return false, "Native computer screen size is fixed."
    end
    if not parentTerm.setTextScale then
        return false, "Text scale works only on monitor terminals."
    end
    local value = tonumber(uiSettings.textScale)
    if not value then
        return false, "Bad scale value."
    end
    local ok, err = pcall(parentTerm.setTextScale, value)
    if ok then
        W, H = term.getSize()
        taskbarY = H
        return true, "Scale applied."
    end
    return false, tostring(err)
end

local function settingsApp(ctx)
    local t = ctx.term
    local gradients = { "blue", "green", "gray", "sunset" }
    local iconSizes = { "tiny", "small", "normal", "large" }
    local scales = { "native", "0.5", "1", "2", "3", "4", "5" }
    local status = "Ready."

    local function cycle(list, value)
        for i, item in ipairs(list) do
            if item == value then
                return list[(i % #list) + 1]
            end
        end
        return list[1]
    end

    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        t.setBackgroundColor(colors.lightGray)
        t.setTextColor(colors.black)
        t.setCursorPos(1, 1)
        t.write(pad("Display settings", w))

        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.setCursorPos(1, 3)
        t.write(shorten("[Gradient] " .. uiSettings.gradient, w))
        t.setCursorPos(1, 5)
        t.write(shorten("[Icons]    " .. uiSettings.iconSize, w))
        t.setCursorPos(1, 7)
        t.write(shorten("[Scale]    " .. uiSettings.textScale, w))
        t.setCursorPos(1, 9)
        local passLabel = uiSettings.password ~= "" and "set" or "empty"
        t.write(shorten("[Password] " .. passLabel, w))
        t.setCursorPos(1, 11)
        t.write(shorten("[MarketID] " .. (uiSettings.marketServer ~= "" and uiSettings.marketServer or "broadcast"), w))
        t.setCursorPos(1, 13)
        t.write(shorten("[AutoUpd]  " .. uiSettings.autoUpdate, w))
        t.setCursorPos(1, 15)
        t.write(shorten("[Apply] [Close]", w))

        t.setTextColor(colors.lightGray)
        t.setCursorPos(1, h)
        t.write(shorten(status, w))
    end

    local function apply()
        saveSettings()
        local ok, message = applyTextScaleSetting()
        if ok then
            status = message
        elseif uiSettings.textScale == "native" then
            status = "Saved. Computer terminal resolution is fixed."
        else
            status = message
        end
    end

    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 3 and x >= 1 and x <= 10 then
                uiSettings.gradient = cycle(gradients, uiSettings.gradient)
                saveSettings()
                status = "Gradient saved."
            elseif y == 5 and x >= 1 and x <= 10 then
                uiSettings.iconSize = cycle(iconSizes, uiSettings.iconSize)
                saveSettings()
                status = "Icon size saved."
            elseif y == 7 and x >= 1 and x <= 10 then
                uiSettings.textScale = cycle(scales, uiSettings.textScale)
                status = "Scale selected. Press Apply."
            elseif y == 9 and x >= 1 and x <= 10 then
                local value = promptLine(ctx, "New password(empty clears): ")
                if value ~= nil then
                    uiSettings.password = value
                    saveSettings()
                    status = value == "" and "Password cleared." or "Password saved."
                end
            elseif y == 11 and x >= 1 and x <= 10 then
                local value = promptLine(ctx, "Market server ID(empty broadcast): ", uiSettings.marketServer)
                if value ~= nil then
                    uiSettings.marketServer = value
                    saveSettings()
                    status = value == "" and "Market uses broadcast." or "Market server saved."
                end
            elseif y == 13 and x >= 1 and x <= 10 then
                uiSettings.autoUpdate = uiSettings.autoUpdate == "off" and "on" or "off"
                saveSettings()
                status = "Auto-update " .. uiSettings.autoUpdate
            elseif y == 15 and x >= 1 and x <= 7 then
                apply()
            elseif y == 15 and x >= 9 and x <= 15 then
                ctx.close()
                return
            end
        elseif event[1] == "key" then
            if event[2] == keys.escape or event[2] == keys.backspace then
                ctx.close()
                return
            elseif event[2] == keys.enter then
                apply()
            end
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function calculatorApp(ctx)
    local t = ctx.term
    local input = ""
    local result = ""
    local buttons = {
        { "7", "8", "9", "/" },
        { "4", "5", "6", "*" },
        { "1", "2", "3", "-" },
        { "0", ".", "=", "+" },
        { "(", ")", "C", "<" }
    }

    local function evaluate()
        if input == "" then
            result = ""
            return
        end
        if not input:match("^[%d%+%-%*/%%%^%(%)%.%s]+$") then
            result = "Bad input"
            return
        end
        local source = "return " .. input
        local fn, err
        if load then
            local ok, loaded, loadErr = pcall(load, source, "calculator", "t", {})
            if ok then
                fn, err = loaded, loadErr
            end
        end
        if not fn and loadstring then
            fn, err = loadstring(source)
        end
        if not fn then
            result = tostring(err or "Error")
            return
        end
        local ok, value = pcall(fn)
        result = ok and tostring(value) or "Error"
    end

    local function press(value)
        if value == "=" then
            evaluate()
        elseif value == "C" then
            input = ""
            result = ""
        elseif value == "<" then
            input = input:sub(1, #input - 1)
        else
            input = input .. value
        end
    end

    local function draw()
        local w = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        t.setCursorPos(1, 1)
        t.write(shorten(input ~= "" and input or "0", w))
        t.setTextColor(colors.lime)
        t.setCursorPos(1, 2)
        t.write(shorten(result, w))

        for row, values in ipairs(buttons) do
            for col, value in ipairs(values) do
                local x = 1 + (col - 1) * 5
                local y = 4 + (row - 1) * 2
                t.setBackgroundColor(colors.lightGray)
                t.setTextColor(colors.black)
                t.setCursorPos(x, y)
                t.write(pad(value, 4))
            end
        end
    end

    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "char" then
            if event[2]:match("[%d%+%-%*/%%%^%(%)%.]") then
                input = input .. event[2]
            end
        elseif event[1] == "key" then
            if event[2] == keys.enter then
                evaluate()
            elseif event[2] == keys.backspace then
                input = input:sub(1, #input - 1)
            elseif event[2] == keys.escape then
                ctx.close()
                return
            end
        elseif event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            local row = math.floor((y - 4) / 2) + 1
            local col = math.floor((x - 1) / 5) + 1
            if buttons[row] and buttons[row][col] and y >= 4 and y <= 12 then
                press(buttons[row][col])
            end
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local paintColorList = {
    colors.white, colors.orange, colors.magenta, colors.lightBlue,
    colors.yellow, colors.lime, colors.pink, colors.gray,
    colors.lightGray, colors.cyan, colors.purple, colors.blue,
    colors.brown, colors.green, colors.red, colors.black
}

local paintBlit = {
    [colors.white] = "0", [colors.orange] = "1", [colors.magenta] = "2", [colors.lightBlue] = "3",
    [colors.yellow] = "4", [colors.lime] = "5", [colors.pink] = "6", [colors.gray] = "7",
    [colors.lightGray] = "8", [colors.cyan] = "9", [colors.purple] = "a", [colors.blue] = "b",
    [colors.brown] = "c", [colors.green] = "d", [colors.red] = "e", [colors.black] = "f"
}

local function paintApp(ctx)
    local t = ctx.term
    local currentColor = colors.black
    local canvas = {}
    local status = "Ready."

    local function setPixel(x, y)
        local cy = y - 2
        if cy < 1 then
            return
        end
        canvas[cy] = canvas[cy] or {}
        canvas[cy][x] = currentColor
    end

    local function saveImage()
        local w, h = t.getSize()
        local path = promptLine(ctx, "Save path: ", fs.combine(DESKTOP, "paint.nfp"))
        if not path or path == "" then
            return
        end
        path = normalizePath(path)
        local out = {}
        for y = 1, h - 2 do
            local line = {}
            for x = 1, w do
                local c = canvas[y] and canvas[y][x] or colors.white
                line[#line + 1] = paintBlit[c] or "0"
            end
            out[#out + 1] = table.concat(line)
        end
        local ok, err = writeFile(path, table.concat(out, "\n"))
        status = ok and ("Saved " .. path) or tostring(err)
    end

    local function clearCanvas()
        canvas = {}
        status = "Cleared."
    end

    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()

        for i, color in ipairs(paintColorList) do
            if i <= w then
                t.setCursorPos(i, 1)
                t.setBackgroundColor(color)
                t.write(" ")
            end
        end
        t.setBackgroundColor(colors.lightGray)
        t.setTextColor(colors.black)
        if w >= 23 then
            t.setCursorPos(18, 1)
            t.write("Save")
        end
        if w >= 30 then
            t.setCursorPos(24, 1)
            t.write("Clear")
        end

        for y = 3, h - 1 do
            for x = 1, w do
                local c = canvas[y - 2] and canvas[y - 2][x] or colors.white
                t.setCursorPos(x, y)
                t.setBackgroundColor(c)
                t.write(" ")
            end
        end

        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.lightGray)
        t.setCursorPos(1, h)
        t.write(shorten(status, w))
    end

    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" or event[1] == "mouse_drag" then
            local _, _, x, y = unpack(event)
            if y == 1 and event[1] == "mouse_click" then
                if paintColorList[x] then
                    currentColor = paintColorList[x]
                    status = "Color selected."
                elseif x >= 18 and x <= 21 then
                    saveImage()
                elseif x >= 24 and x <= 28 then
                    clearCanvas()
                end
            elseif y >= 3 then
                setPixel(x, y)
            end
        elseif event[1] == "key" then
            if event[2] == keys.s then
                saveImage()
            elseif event[2] == keys.c then
                clearCanvas()
            elseif event[2] == keys.escape or event[2] == keys.backspace then
                ctx.close()
                return
            end
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function clockApp(ctx)
    local t = ctx.term
    local timer = os.startTimer(1)
    while true do
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        local line1 = "Minecraft Clock"
        local line2 = minecraftClockText()
        t.setCursorPos(math.max(1, math.floor((w - #line1) / 2) + 1), math.max(1, math.floor(h / 2) - 2))
        t.write(line1)
        t.setTextColor(colors.lime)
        t.setCursorPos(math.max(1, math.floor((w - #line2) / 2) + 1), math.max(2, math.floor(h / 2)))
        t.write(line2)
        t.setTextColor(colors.lightGray)
        t.setCursorPos(1, h)
        t.write(shorten("Esc closes. Time is based on os.time()/os.day().", w))

        local event = { ctx.pullEvent() }
        if event[1] == "timer" and event[2] == timer then
            timer = os.startTimer(1)
        elseif event[1] == "key" and (event[2] == keys.escape or event[2] == keys.backspace) then
            ctx.close()
            return
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function sheetsApp(ctx)
    local t = ctx.term
    local cols = { "A", "B", "C", "D", "E", "F" }
    local rows = 24
    local cells = {}
    local selectedCol, selectedRow = 1, 1
    local scroll = 0
    local status = "Ready."
    local defaultPath = fs.combine(DESKTOP, "sheet.tsv")

    local function keyFor(col, row)
        return cols[col] .. tostring(row)
    end

    local function cellValue(col, row)
        return cells[keyFor(col, row)] or ""
    end

    local function numericValue(col, row, depth)
        depth = depth or 0
        if depth > 8 then return 0 end
        local value = cellValue(col, row)
        if value:sub(1, 1) == "=" then
            value = value:sub(2)
            value = value:gsub("SUM%((%a)(%d+):(%a)(%d+)%)", function(c1, r1, c2, r2)
                local a, b = nil, nil
                for i, c in ipairs(cols) do
                    if c == c1:upper() then a = i end
                    if c == c2:upper() then b = i end
                end
                local sum = 0
                if a and b then
                    for rowIndex = tonumber(r1), tonumber(r2) do
                        for colIndex = math.min(a, b), math.max(a, b) do
                            sum = sum + numericValue(colIndex, rowIndex, depth + 1)
                        end
                    end
                end
                return tostring(sum)
            end)
            value = value:gsub("(%a)(%d+)", function(c, r)
                for i, name in ipairs(cols) do
                    if name == c:upper() then
                        return tostring(numericValue(i, tonumber(r), depth + 1))
                    end
                end
                return "0"
            end)
            if value:match("^[%d%+%-%*/%%%^%(%)%.%s]+$") then
                local fn
                if load then
                    local ok, loaded = pcall(load, "return " .. value, "sheet", "t", {})
                    if ok then fn = loaded end
                end
                if not fn and loadstring then
                    fn = loadstring("return " .. value)
                end
                if fn then
                    local ok, result = pcall(fn)
                    if ok and tonumber(result) then
                        return tonumber(result)
                    end
                end
            end
            return 0
        end
        return tonumber(value) or 0
    end

    local function displayValue(col, row)
        local value = cellValue(col, row)
        if value:sub(1, 1) == "=" then
            return tostring(numericValue(col, row))
        end
        return value
    end

    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        t.setBackgroundColor(colors.lightGray)
        t.setTextColor(colors.black)
        t.setCursorPos(1, 1)
        t.write(pad("[Edit] [Save] [Load] [Print]", w))
        t.setBackgroundColor(colors.gray)
        t.setTextColor(colors.white)
        t.setCursorPos(1, 2)
        t.write("   ")
        for col = 1, #cols do
            t.write(pad(cols[col], 8))
        end
        local visible = h - 4
        for y = 1, visible do
            local row = scroll + y
            if row > rows then break end
            t.setCursorPos(1, y + 2)
            t.setBackgroundColor(colors.gray)
            t.setTextColor(colors.white)
            t.write(pad(tostring(row), 3))
            for col = 1, #cols do
                local selected = col == selectedCol and row == selectedRow
                t.setBackgroundColor(selected and colors.blue or colors.black)
                t.setTextColor(colors.white)
                t.write(pad(shorten(displayValue(col, row), 8), 8))
            end
        end
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.lightGray)
        t.setCursorPos(1, h)
        t.write(shorten(status .. "  " .. keyFor(selectedCol, selectedRow) .. "=" .. cellValue(selectedCol, selectedRow), w))
    end

    local function editCell()
        local key = keyFor(selectedCol, selectedRow)
        local value = promptLine(ctx, key .. ": ", cells[key] or "")
        if value ~= nil then
            cells[key] = value
            status = "Edited " .. key
        end
    end

    local function saveSheet()
        local path = promptLine(ctx, "Save TSV: ", defaultPath)
        if not path or path == "" then return end
        path = normalizePath(path)
        local lines = {}
        for row = 1, rows do
            local parts = {}
            for col = 1, #cols do
                parts[#parts + 1] = cellValue(col, row):gsub("\t", " ")
            end
            lines[#lines + 1] = table.concat(parts, "\t")
        end
        local ok, err = writeFile(path, table.concat(lines, "\n"))
        status = ok and ("Saved " .. path) or tostring(err)
    end

    local function loadSheet()
        local path = promptLine(ctx, "Load TSV: ", defaultPath)
        if not path or path == "" then return end
        path = normalizePath(path)
        local text = readFile(path)
        if not text then
            status = "Cannot read file."
            return
        end
        cells = {}
        local row = 1
        for line in (text .. "\n"):gmatch("(.-)\n") do
            local col = 1
            for value in (line .. "\t"):gmatch("(.-)\t") do
                if col <= #cols and value ~= "" then
                    cells[keyFor(col, row)] = value
                end
                col = col + 1
            end
            row = row + 1
            if row > rows then break end
        end
        status = "Loaded " .. path
    end

    local function findPrinter()
        if peripheral and peripheral.find then
            local printer = peripheral.find("printer")
            if printer then return printer end
        end
        for _, side in ipairs(modemSides()) do
            if peripheral.getType(side) == "printer" then
                return peripheral.wrap(side)
            end
        end
        return nil
    end

    local function printSheet()
        local printer = findPrinter()
        if not printer then
            status = "No printer found."
            return
        end
        if not printer.newPage() then
            status = "Printer has no paper/ink."
            return
        end
        if printer.setPageTitle then printer.setPageTitle("AurumOS sheet") end
        printer.setCursorPos(1, 1)
        printer.write("AurumOS Sheet")
        for row = 1, math.min(rows, 18) do
            printer.setCursorPos(1, row + 2)
            local parts = {}
            for col = 1, #cols do
                parts[#parts + 1] = shorten(displayValue(col, row), 5)
            end
            printer.write(table.concat(parts, " "))
        end
        printer.endPage()
        status = "Printed."
    end

    local function toolbar(x)
        if x >= 1 and x <= 6 then return "edit" end
        if x >= 8 and x <= 13 then return "save" end
        if x >= 15 and x <= 20 then return "load" end
        if x >= 22 and x <= 28 then return "print" end
        return nil
    end

    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 then
                local action = toolbar(x)
                if action == "edit" then editCell()
                elseif action == "save" then saveSheet()
                elseif action == "load" then loadSheet()
                elseif action == "print" then printSheet() end
            elseif y >= 3 then
                local col = math.floor((x - 4) / 8) + 1
                local row = scroll + y - 2
                if col >= 1 and col <= #cols and row >= 1 and row <= rows then
                    selectedCol, selectedRow = col, row
                end
            end
        elseif event[1] == "key" then
            if event[2] == keys.enter then editCell()
            elseif event[2] == keys.left then selectedCol = max(1, selectedCol - 1)
            elseif event[2] == keys.right then selectedCol = min(#cols, selectedCol + 1)
            elseif event[2] == keys.up then selectedRow = max(1, selectedRow - 1)
            elseif event[2] == keys.down then selectedRow = min(rows, selectedRow + 1)
            elseif event[2] == keys.s then saveSheet()
            elseif event[2] == keys.l then loadSheet()
            elseif event[2] == keys.p then printSheet()
            elseif event[2] == keys.escape or event[2] == keys.backspace then ctx.close(); return end
            local visible = select(2, t.getSize()) - 4
            if selectedRow <= scroll then scroll = max(0, selectedRow - 1) end
            if selectedRow > scroll + visible then scroll = selectedRow - visible end
        elseif event[1] == "mouse_scroll" then
            scroll = clamp(scroll + event[2], 0, max(0, rows - 1))
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local luaKeywords = {
    "and","break","do","else","elseif","end","false","for","function","if","in","local","nil",
    "not","or","repeat","return","then","true","until","while","print","pairs","ipairs","pcall",
    "term","colors","fs","shell","rednet","peripheral","textutils","os.pullEvent","os.startTimer"
}

local keywordSet = {}
for _, word in ipairs(luaKeywords) do keywordSet[word] = true end

local function codeStudioApp(ctx)
    local t = ctx.term
    local lines = { "" }
    local path = fs.combine(PROGRAMS, "new.lua")
    local cursorX, cursorY, scroll = 1, 1, 0
    local status = "Lua editor. Tab completes."

    local function currentLine()
        return lines[cursorY] or ""
    end

    local function setLine(value)
        lines[cursorY] = value
    end

    local function prefixAtCursor()
        local left = currentLine():sub(1, cursorX - 1)
        return left:match("([%w_%.]+)$") or ""
    end

    local function suggestion()
        local prefix = prefixAtCursor()
        if prefix == "" then return nil end
        for _, word in ipairs(luaKeywords) do
            if word:sub(1, #prefix) == prefix and word ~= prefix then
                return word, prefix
            end
        end
        return nil
    end

    local function colorToken(token)
        if keywordSet[token] then return colors.purple end
        if token:match("^%d") then return colors.lightBlue end
        if token:match("^term") or token:match("^fs") or token:match("^os") or token:match("^shell") or token:match("^rednet") then
            return colors.cyan
        end
        return colors.white
    end

    local function writeColor(text, fg)
        t.setTextColor(fg)
        t.write(text)
    end

    local function drawHighlighted(line, width)
        local i = 1
        while i <= #line and i <= width do
            local comment = line:find("--", i, true)
            if comment == i then
                writeColor(line:sub(i, width), colors.green)
                return
            end
            local ch = line:sub(i, i)
            if ch == '"' or ch == "'" then
                local j = i + 1
                while j <= #line and line:sub(j, j) ~= ch do j = j + 1 end
                writeColor(line:sub(i, min(j, width)), colors.orange)
                i = j + 1
            else
                local token = line:sub(i):match("^[%w_%.]+")
                if token then
                    writeColor(token:sub(1, width - i + 1), colorToken(token))
                    i = i + #token
                else
                    writeColor(ch, colors.white)
                    i = i + 1
                end
            end
        end
    end

    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        t.setBackgroundColor(colors.lightGray)
        t.setTextColor(colors.black)
        t.setCursorPos(1, 1)
        t.write(pad("[Open] [Save] [Run] [New]", w))
        t.setBackgroundColor(colors.black)
        for row = 1, h - 3 do
            local index = scroll + row
            if index > #lines then break end
            t.setCursorPos(1, row + 1)
            t.setTextColor(colors.gray)
            t.write(pad(tostring(index), 3))
            drawHighlighted(lines[index], w - 4)
        end
        local suggest = suggestion()
        t.setCursorPos(1, h)
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.lightGray)
        t.write(shorten(status .. (suggest and ("  Tab: " .. suggest) or ""), w))
        t.setCursorBlink(true)
        t.setCursorPos(min(w, 4 + cursorX), clamp(cursorY - scroll + 1, 2, h - 2))
    end

    local function saveCode()
        local newPath = promptLine(ctx, "Save path: ", path)
        if not newPath or newPath == "" then return end
        path = normalizePath(newPath)
        local ok, err = writeFile(path, table.concat(lines, "\n"))
        status = ok and ("Saved " .. path) or tostring(err)
    end

    local function openCode()
        local newPath = promptLine(ctx, "Open path: ", path)
        if not newPath or newPath == "" then return end
        newPath = normalizePath(newPath)
        local text = readFile(newPath)
        if not text then status = "Cannot read file."; return end
        lines = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
        if #lines == 0 then lines = { "" } end
        path, cursorX, cursorY, scroll = newPath, 1, 1, 0
        status = "Opened " .. path
    end

    local function runCode()
        if fs.exists(path) then
            ctx.openPath(path)
        else
            status = "Save first."
        end
    end

    local function newCode()
        lines, path, cursorX, cursorY, scroll = { "" }, fs.combine(PROGRAMS, "new.lua"), 1, 1, 0
        status = "New file."
    end

    local function toolbar(x)
        if x >= 1 and x <= 6 then return "open" end
        if x >= 8 and x <= 13 then return "save" end
        if x >= 15 and x <= 19 then return "run" end
        if x >= 21 and x <= 25 then return "new" end
        return nil
    end

    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "char" then
            local line = currentLine()
            setLine(line:sub(1, cursorX - 1) .. event[2] .. line:sub(cursorX))
            cursorX = cursorX + 1
        elseif event[1] == "paste" then
            local text = tostring(event[2] or "")
            local line = currentLine()
            setLine(line:sub(1, cursorX - 1) .. text .. line:sub(cursorX))
            cursorX = cursorX + #text
        elseif event[1] == "key" then
            if event[2] == keys.tab then
                local word, prefix = suggestion()
                if word then
                    local line = currentLine()
                    setLine(line:sub(1, cursorX - #prefix - 1) .. word .. line:sub(cursorX))
                    cursorX = cursorX + #word - #prefix
                end
            elseif event[2] == keys.enter then
                local line = currentLine()
                lines[cursorY] = line:sub(1, cursorX - 1)
                table.insert(lines, cursorY + 1, line:sub(cursorX))
                cursorY, cursorX = cursorY + 1, 1
            elseif event[2] == keys.backspace then
                if cursorX > 1 then
                    local line = currentLine()
                    setLine(line:sub(1, cursorX - 2) .. line:sub(cursorX))
                    cursorX = cursorX - 1
                elseif cursorY > 1 then
                    local prev = lines[cursorY - 1]
                    cursorX = #prev + 1
                    lines[cursorY - 1] = prev .. currentLine()
                    table.remove(lines, cursorY)
                    cursorY = cursorY - 1
                end
            elseif event[2] == keys.left then cursorX = max(1, cursorX - 1)
            elseif event[2] == keys.right then cursorX = min(#currentLine() + 1, cursorX + 1)
            elseif event[2] == keys.up then cursorY = max(1, cursorY - 1); cursorX = min(cursorX, #currentLine() + 1)
            elseif event[2] == keys.down then cursorY = min(#lines, cursorY + 1); cursorX = min(cursorX, #currentLine() + 1)
            elseif event[2] == keys.escape then ctx.close(); return end
        elseif event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 then
                local action = toolbar(x)
                if action == "open" then openCode()
                elseif action == "save" then saveCode()
                elseif action == "run" then runCode()
                elseif action == "new" then newCode() end
            elseif y >= 2 then
                local row = scroll + y - 1
                if row >= 1 and row <= #lines then
                    cursorY = row
                    cursorX = min(max(1, x - 3), #currentLine() + 1)
                end
            end
        elseif event[1] == "mouse_scroll" then
            scroll = clamp(scroll + event[2], 0, max(0, #lines - 1))
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
        local visible = select(2, t.getSize()) - 3
        if cursorY <= scroll then scroll = max(0, cursorY - 1) end
        if cursorY > scroll + visible then scroll = cursorY - visible end
    end
end

local function biosApp(ctx)
    local t = ctx.term
    local status = "Boot tools. Press B during startup for console BIOS."
    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        t.setBackgroundColor(colors.lightGray)
        t.setTextColor(colors.black)
        t.setCursorPos(1, 1)
        t.write(pad("AurumOS BIOS", w))
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.setCursorPos(1, 3)
        t.write("[Reinstall]")
        t.setCursorPos(1, 5)
        t.write("[Boot Path]")
        t.setCursorPos(1, 7)
        t.write("[Native Shell]")
        t.setCursorPos(1, 9)
        t.write("[Reboot]")
        t.setTextColor(colors.lightGray)
        t.setCursorPos(1, h)
        t.write(shorten(status, w))
    end
    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if x >= 1 and y == 3 then
                local installer = fs.exists("/install.lua") and "/install.lua" or "install.lua"
                if shell and shell.run and fs.exists(installer) then
                    shell.run(installer)
                else
                    status = "install.lua not found."
                end
            elseif x >= 1 and y == 5 then
                local path = promptLine(ctx, "Boot path: ")
                if path and path ~= "" and shell and shell.run then
                    shell.run(path)
                end
            elseif x >= 1 and y == 7 then
                ctx.exitToShell()
                return
            elseif x >= 1 and y == 9 then
                os.reboot()
            end
        elseif event[1] == "key" and (event[2] == keys.escape or event[2] == keys.backspace) then
            ctx.close()
            return
        elseif event[1] == "terminate" then
            ctx.close()
            return
        end
    end
end

local function versionNewer(a, b)
    local aa, bb = {}, {}
    for n in tostring(a or ""):gmatch("%d+") do aa[#aa + 1] = tonumber(n) end
    for n in tostring(b or ""):gmatch("%d+") do bb[#bb + 1] = tonumber(n) end
    for i = 1, math.max(#aa, #bb) do
        local av, bv = aa[i] or 0, bb[i] or 0
        if av > bv then return true end
        if av < bv then return false end
    end
    return false
end

local function marketRequest(packet, timeout)
    local ok, err = openRednetModem()
    if not ok then
        return nil, err
    end
    local target = tonumber(uiSettings.marketServer or "")
    if target then
        rednet.send(target, packet, MARKET_PROTOCOL)
    else
        rednet.broadcast(packet, MARKET_PROTOCOL)
    end
    local timer = os.startTimer(timeout or 4)
    while true do
        local event = { os.pullEventRaw() }
        if event[1] == "rednet_message" and event[4] == MARKET_PROTOCOL then
            return event[3], tostring(event[2])
        elseif event[1] == "timer" and event[2] == timer then
            return nil, "No Tiny Market server answered."
        end
    end
end

local function installMarketFile(path, content)
    path = normalizePath(path)
    local ok, err = writeFile(path, content or "")
    return ok, err
end

local function autoUpdateCheck(silent)
    if uiSettings.autoUpdate == "off" then
        return false, "Auto-update is off."
    end
    local response = marketRequest({ action = "update", os = OS_NAME, version = VERSION }, 2)
    if type(response) ~= "table" or not response.version then
        return false, silent and "" or "No update server."
    end
    if not versionNewer(response.version, VERSION) then
        return false, "Already current."
    end
    if type(response.files) ~= "table" then
        return false, "Update has no files."
    end
    for _, file in ipairs(response.files) do
        if type(file) == "table" and file.path and file.content then
            local ok, err = installMarketFile(file.path, file.content)
            if not ok then
                return false, err
            end
        end
    end
    saveSettings()
    os.reboot()
    return true, "Updating."
end

local function marketApp(ctx)
    local t = ctx.term
    local catalog = {}
    local selected = 1
    local status = "Set server ID in Settings or use broadcast."

    local function refresh()
        local response, err = marketRequest({ action = "catalog", version = VERSION }, 4)
        if type(response) == "table" and type(response.apps) == "table" then
            catalog = response.apps
            status = "Catalog loaded from " .. tostring(err)
        else
            status = err or "No catalog."
        end
    end

    local function installSelected()
        local app = catalog[selected]
        if not app then return end
        local response, err = marketRequest({ action = "install", id = app.id }, 5)
        if type(response) ~= "table" or response.ok ~= true then
            status = (type(response) == "table" and response.error) or err or "Install failed."
            return
        end
        local installed = 0
        for _, file in ipairs(response.files or {}) do
            local ok, writeErr = installMarketFile(file.path, file.content)
            if ok then installed = installed + 1 else status = writeErr; return end
        end
        status = "Installed " .. tostring(installed) .. " file(s)."
    end

    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        t.setBackgroundColor(colors.lightGray)
        t.setTextColor(colors.black)
        t.setCursorPos(1, 1)
        t.write(pad("[Refresh] [Install] [Update]", w))
        t.setBackgroundColor(colors.black)
        for i = 1, h - 3 do
            local app = catalog[i]
            if app then
                t.setCursorPos(1, i + 1)
                t.setBackgroundColor(i == selected and colors.blue or colors.black)
                t.setTextColor(colors.white)
                t.write(pad(shorten((app.title or app.id) .. " " .. (app.version or ""), w), w))
            end
        end
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.lightGray)
        t.setCursorPos(1, h)
        t.write(shorten(status, w))
    end

    refresh()
    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 then
                if x <= 9 then refresh()
                elseif x >= 11 and x <= 19 then installSelected()
                elseif x >= 21 then local _, msg = autoUpdateCheck(false); status = msg end
            elseif y > 1 and catalog[y - 1] then
                selected = y - 1
            end
        elseif event[1] == "key" then
            if event[2] == keys.up then selected = max(1, selected - 1)
            elseif event[2] == keys.down then selected = min(#catalog, selected + 1)
            elseif event[2] == keys.enter then installSelected()
            elseif event[2] == keys.r then refresh()
            elseif event[2] == keys.escape or event[2] == keys.backspace then ctx.close(); return end
        elseif event[1] == "terminate" then ctx.close(); return end
    end
end

local function turtleRemoteApp(ctx)
    local t = ctx.term
    local targetId = nil
    local status = "Enter turtle ID."
    local inventory = {}
    local buttons = {
        { "F", "forward" }, { "B", "back" }, { "L", "turnLeft" }, { "R", "turnRight" },
        { "Up", "up" }, { "Dn", "down" }, { "Dig", "dig" }, { "DigU", "digUp" },
        { "DigD", "digDown" }, { "Place", "place" }, { "PlU", "placeUp" }, { "PlD", "placeDown" },
        { "Inv", "inventory" }, { "Refuel", "refuel" }
    }

    local function sendCommand(cmd)
        if not targetId then
            local id = tonumber(promptLine(ctx, "Turtle ID: "))
            if not id then status = "Bad ID."; return end
            targetId = id
        end
        local ok, err = openRednetModem()
        if not ok then status = err; return end
        rednet.send(targetId, { app = "AurumTurtle", cmd = cmd }, TURTLE_PROTOCOL)
        local timer = os.startTimer(3)
        while true do
            local event = { ctx.pullEvent() }
            if event[1] == "rednet_message" and event[2] == targetId and event[4] == TURTLE_PROTOCOL then
                local msg = event[3]
                if type(msg) == "table" then
                    status = tostring(msg.ok) .. " " .. tostring(msg.message or "")
                    if msg.inventory then inventory = msg.inventory end
                end
                return
            elseif event[1] == "timer" and event[2] == timer then
                status = "No turtle response."
                return
            end
        end
    end

    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.white)
        t.clear()
        t.setBackgroundColor(colors.lightGray)
        t.setTextColor(colors.black)
        t.setCursorPos(1, 1)
        t.write(pad("[ID] Turtle Remote " .. (targetId and ("#" .. targetId) or ""), w))
        for i, button in ipairs(buttons) do
            local col = ((i - 1) % 4)
            local row = math.floor((i - 1) / 4)
            local x, y = 1 + col * 8, 3 + row * 2
            t.setCursorPos(x, y)
            t.setBackgroundColor(colors.blue)
            t.setTextColor(colors.white)
            t.write(pad(button[1], 7))
        end
        local baseY = 11
        t.setBackgroundColor(colors.black)
        t.setTextColor(colors.lightGray)
        t.setCursorPos(1, baseY)
        t.write("Inventory:")
        for i = 1, math.min(#inventory, h - baseY - 1) do
            t.setCursorPos(1, baseY + i)
            t.write(shorten(tostring(i) .. ": " .. tostring(inventory[i]), w))
        end
        t.setCursorPos(1, h)
        t.write(shorten(status, w))
    end

    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 and x <= 4 then
                local id = tonumber(promptLine(ctx, "Turtle ID: ", tostring(targetId or "")))
                if id then targetId = id; status = "Target set." end
            else
                local col = math.floor((x - 1) / 8)
                local row = math.floor((y - 3) / 2)
                local index = row * 4 + col + 1
                if buttons[index] then sendCommand(buttons[index][2]) end
            end
        elseif event[1] == "key" and (event[2] == keys.escape or event[2] == keys.backspace) then
            ctx.close(); return
        elseif event[1] == "terminate" then ctx.close(); return end
    end
end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if y > 0 then return math.pi / 2 end
    if y < 0 then return -math.pi / 2 end
    return 0
end

local function ballisticsApp(ctx)
    local t = ctx.term
    local result = "Enter data. CBC physics is approximate."
    local function askNumber(label, default)
        local v = tonumber(promptLine(ctx, label .. ": ", tostring(default or 0)))
        return v or tonumber(default) or 0
    end
    local function solve()
        local x1, y1, z1 = askNumber("Cannon X", 0), askNumber("Cannon Y", 64), askNumber("Cannon Z", 0)
        local x2, y2, z2 = askNumber("Target X", 0), askNumber("Target Y", 64), askNumber("Target Z", 0)
        local facing = (promptLine(ctx, "Current facing N/E/S/W: ", "N") or "N"):upper()
        local dx, dz, dy = x2 - x1, z2 - z1, y2 - y1
        local range = math.sqrt(dx * dx + dz * dz)
        local yaw = (math.deg(atan2(-dx, dz)) + 360) % 360
        local facingYaw = ({ N = 0, E = 90, S = 180, W = 270 })[facing] or 0
        local turn = ((yaw - facingYaw + 540) % 360) - 180
        local g = 0.05
        local charge, pitch = nil, nil
        for c = 1, 32 do
            local v = c * 8
            local disc = v ^ 4 - g * (g * range ^ 2 + 2 * dy * v ^ 2)
            if disc >= 0 and range > 0 then
                local tanTheta = (v ^ 2 - math.sqrt(disc)) / (g * range)
                pitch = math.deg(math.atan(tanTheta))
                charge = c
                break
            end
        end
        if charge then
            result = "Charge " .. charge .. "  Pitch " .. string.format("%.1f", pitch) ..
                " deg  Yaw " .. string.format("%.1f", yaw) .. " deg  Turn " .. string.format("%.1f", turn) .. " deg"
        else
            result = "No low-arc solution in 32 charges. Raise cannon or use high arc."
        end
    end
    while true do
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.clear()
        t.setBackgroundColor(colors.lightGray); t.setTextColor(colors.black); t.setCursorPos(1,1)
        t.write(pad("[Calculate] [Close]", w))
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.setCursorPos(1,3)
        t.write(shorten("Create Big Cannons ballistic helper", w))
        t.setCursorPos(1,5); t.write(shorten(result, w))
        t.setTextColor(colors.lightGray); t.setCursorPos(1,h)
        t.write(shorten("Approximation: velocity ~= charge*8, gravity 0.05.", w))
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 and x <= 11 then solve()
            elseif y == 1 and x >= 13 then ctx.close(); return end
        elseif event[1] == "key" then
            if event[2] == keys.enter then solve()
            elseif event[2] == keys.escape or event[2] == keys.backspace then ctx.close(); return end
        elseif event[1] == "terminate" then ctx.close(); return end
    end
end

local function engineeringCalcApp(ctx)
    local t = ctx.term
    local status = "Use: 1/2 + 3/4, sqrt 9, sin 30"
    local function gcd(a, b)
        a, b = math.abs(a), math.abs(b)
        while b ~= 0 do a, b = b, a % b end
        return a == 0 and 1 or a
    end
    local function parseFrac(s)
        local a, b = tostring(s):match("^%s*([%-]?%d+)%s*/%s*([%-]?%d+)%s*$")
        if a then return tonumber(a), tonumber(b) end
        return tonumber(s) or 0, 1
    end
    local function fmt(n, d)
        if d < 0 then n, d = -n, -d end
        local g = gcd(n, d)
        n, d = n / g, d / g
        if d == 1 then return tostring(n) end
        return tostring(n) .. "/" .. tostring(d) .. " = " .. tostring(n / d)
    end
    local function calc()
        local expr = promptLine(ctx, "Expr: ")
        if not expr or expr == "" then return end
        local fn, arg = expr:match("^%s*(sqrt|sin|cos|tan)%s+(.+)$")
        if fn then
            local n, d = parseFrac(arg)
            local v = n / d
            if fn ~= "sqrt" then v = math.rad(v) end
            local r = ({ sqrt = math.sqrt, sin = math.sin, cos = math.cos, tan = math.tan })[fn](v)
            status = fn .. " = " .. string.format("%.6f", r)
            return
        end
        local a, op, b = expr:match("^%s*(.-)%s*([%+%-%*/%^])%s*(.-)%s*$")
        if not a then status = "Bad expression."; return end
        local n1, d1 = parseFrac(a)
        local n2, d2 = parseFrac(b)
        local rn, rd
        if op == "+" then rn, rd = n1 * d2 + n2 * d1, d1 * d2
        elseif op == "-" then rn, rd = n1 * d2 - n2 * d1, d1 * d2
        elseif op == "*" then rn, rd = n1 * n2, d1 * d2
        elseif op == "/" then rn, rd = n1 * d2, d1 * n2
        elseif op == "^" then status = tostring((n1 / d1) ^ (n2 / d2)); return end
        if rd == 0 then status = "Division by zero." else status = expr .. " = " .. fmt(rn, rd) end
    end
    while true do
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.clear()
        t.setBackgroundColor(colors.lightGray); t.setTextColor(colors.black); t.setCursorPos(1,1)
        t.write(pad("[Input] [Close]", w))
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.setCursorPos(1,3)
        t.write(shorten(status, w))
        t.setTextColor(colors.lightGray); t.setCursorPos(1,h)
        t.write(shorten("Fractions are reduced automatically.", w))
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 and x <= 7 then calc()
            elseif y == 1 and x >= 9 then ctx.close(); return end
        elseif event[1] == "key" then
            if event[2] == keys.enter then calc()
            elseif event[2] == keys.escape or event[2] == keys.backspace then ctx.close(); return end
        elseif event[1] == "terminate" then ctx.close(); return end
    end
end

local function addIconApp(ctx)
    local status = "Creates .link icons on Desktop."
    while true do
        local t = ctx.term
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.clear()
        t.setBackgroundColor(colors.lightGray); t.setTextColor(colors.black); t.setCursorPos(1,1)
        t.write(pad("[Create] [Close]", w))
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.setCursorPos(1,3)
        t.write(shorten(status, w))
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 and x <= 8 then
                local title = promptLine(ctx, "Icon title: ")
                local target = promptLine(ctx, "Target path/builtin: ")
                local icon = promptLine(ctx, "Icon letter: ", (title or "A"):sub(1,1))
                if title and target and title ~= "" and target ~= "" then
                    local path = uniquePath(fs.combine(DESKTOP, safeFileName(title) .. ".link"))
                    writeFile(path, "title=" .. title .. "\nicon=" .. (icon or ">"):sub(1,2) .. "\ntarget=" .. target .. "\n")
                    status = "Created " .. fs.getName(path)
                end
            elseif y == 1 and x >= 10 then ctx.close(); return end
        elseif event[1] == "key" and (event[2] == keys.escape or event[2] == keys.backspace) then ctx.close(); return
        elseif event[1] == "terminate" then ctx.close(); return end
    end
end

local function monitorApp(ctx)
    local status = "Choose a monitor side; reboot to use it as main screen."
    while true do
        local t = ctx.term
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.clear()
        t.setBackgroundColor(colors.lightGray); t.setTextColor(colors.black); t.setCursorPos(1,1)
        t.write(pad("[Set] [Clear] [Draw] [Close]", w))
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.setCursorPos(1,3)
        t.write(shorten("Current: " .. tostring(uiSettings.monitorSide), w))
        t.setCursorPos(1,5); t.write(shorten(status, w))
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 and x <= 5 then
                local side = promptLine(ctx, "Monitor side: ", uiSettings.monitorSide)
                if side and peripheral.getType(side) == "monitor" then uiSettings.monitorSide = side; saveSettings(); status = "Saved. Reboot to apply." else status = "No monitor there." end
            elseif y == 1 and x >= 7 and x <= 13 then
                uiSettings.monitorSide = ""; saveSettings(); status = "Cleared."
            elseif y == 1 and x >= 15 and x <= 20 then
                local mon = uiSettings.monitorSide ~= "" and peripheral.wrap(uiSettings.monitorSide)
                if mon then mon.clear(); mon.setCursorPos(1,1); mon.write("AurumOS monitor connected"); status = "Drawn." else status = "No monitor selected." end
            elseif y == 1 and x >= 22 then ctx.close(); return end
        elseif event[1] == "key" and (event[2] == keys.escape or event[2] == keys.backspace) then ctx.close(); return
        elseif event[1] == "terminate" then ctx.close(); return end
    end
end

local function mixerApp(ctx)
    local status = "Click bar or set speaker side."
    while true do
        local t = ctx.term
        local w, h = t.getSize()
        local vol = tonumber(uiSettings.volume or "60") or 60
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.clear()
        t.setBackgroundColor(colors.lightGray); t.setTextColor(colors.black); t.setCursorPos(1,1)
        t.write(pad("[Speaker] [Test] [Close]", w))
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.setCursorPos(1,3)
        t.write("Volume:")
        t.setCursorPos(1,5)
        t.setBackgroundColor(colors.gray); t.write(string.rep(" ", math.min(30, w)))
        t.setCursorPos(1,5); t.setBackgroundColor(colors.lime); t.write(string.rep(" ", math.floor(math.min(30,w) * vol / 100)))
        t.setBackgroundColor(colors.black); t.setTextColor(colors.lightGray); t.setCursorPos(1,h)
        t.write(shorten(status .. " " .. tostring(vol) .. "%", w))
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 and x <= 9 then
                local side = promptLine(ctx, "Speaker side: ", uiSettings.speakerSide)
                if side then uiSettings.speakerSide = side; saveSettings(); status = "Speaker saved." end
            elseif y == 1 and x >= 11 and x <= 16 then playUiSound("click")
            elseif y == 1 and x >= 18 then ctx.close(); return
            elseif y == 5 then uiSettings.volume = tostring(clamp(math.floor(x / math.min(30,w) * 100), 0, 100)); saveSettings(); playUiSound("click") end
        elseif event[1] == "key" and (event[2] == keys.escape or event[2] == keys.backspace) then ctx.close(); return
        elseif event[1] == "terminate" then ctx.close(); return end
    end
end

local function doomMiniApp(ctx)
    local t = ctx.term
    local hp, ammo, kills = 100, 20, 0
    local monsterX = 8
    local tick = os.startTimer(1)
    playUiSound("doom")
    while true do
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black); t.setTextColor(colors.red); t.clear()
        t.setCursorPos(1,1); t.write("DOOM")
        t.setTextColor(colors.white); t.setCursorPos(1,2); t.write("HP " .. hp .. " AMMO " .. ammo .. " KILLS " .. kills)
        for y = 4, h - 2 do
            t.setCursorPos(1,y); t.setBackgroundColor(colors.gray); t.write(string.rep(" ", w))
        end
        t.setBackgroundColor(colors.black); t.setTextColor(colors.red); t.setCursorPos(monsterX, math.max(5, math.floor(h / 2))); t.write("M")
        t.setTextColor(colors.lightGray); t.setCursorPos(1,h); t.write(shorten("Arrows move monster aim, Space fires, Esc exits.", w))
        local event = { ctx.pullEvent() }
        if event[1] == "key" then
            if event[2] == keys.left then monsterX = max(2, monsterX - 1)
            elseif event[2] == keys.right then monsterX = min(w - 1, monsterX + 1)
            elseif event[2] == keys.space then
                if ammo > 0 then ammo = ammo - 1; kills = kills + 1; monsterX = math.random(2, max(2,w - 1)); playUiSound("click") else hp = hp - 5 end
            elseif event[2] == keys.escape then ctx.close(); return end
        elseif event[1] == "timer" and event[2] == tick then
            hp = hp - 1
            tick = os.startTimer(1)
        elseif event[1] == "terminate" then ctx.close(); return end
        if hp <= 0 then hp, ammo = 100, 20; kills = 0; playUiSound("warn") end
    end
end

local function gamesApp(ctx, mode)
    mode = mode or "checkers"
    local t = ctx.term
    local difficulty = "easy"
    local status = "Mode: " .. mode .. ". Click Online for RedNet lobby."
    local board = {}
    for y = 1, 8 do board[y] = {}; for x = 1, 8 do board[y][x] = ((x + y) % 2 == 0) and "." or " " end end
    local function draw()
        local w, h = t.getSize()
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.clear()
        t.setBackgroundColor(colors.lightGray); t.setTextColor(colors.black); t.setCursorPos(1,1)
        t.write(pad("[Bot] [Easy] [Mid] [Hard] [HC] [Online] [Close]", w))
        t.setBackgroundColor(colors.black); t.setTextColor(colors.white); t.setCursorPos(1,3)
        t.write("Game: " .. mode .. "  Bot: " .. difficulty)
        for y = 1, 8 do
            t.setCursorPos(2, y + 4)
            for x = 1, 8 do
                t.setBackgroundColor(((x+y)%2==0) and colors.gray or colors.lightGray)
                t.setTextColor(colors.black)
                local ch = board[y][x]
                if mode == "chess" and y == 1 then ch = "C" elseif mode == "checkers" and y <= 3 and ((x+y)%2==0) then ch = "o" elseif mode == "puzzle" then ch = tostring(((x+y-2)%8)+1) elseif mode == "strategy" then ch = (x==4 and y==4) and "B" or "." end
                t.write(ch .. " ")
            end
        end
        t.setBackgroundColor(colors.black); t.setTextColor(colors.lightGray); t.setCursorPos(1,h)
        t.write(shorten(status, w))
    end
    local function online()
        local id = tonumber(promptLine(ctx, "Host/join ID(empty host): "))
        local ok, err = openRednetModem()
        if not ok then status = err; return end
        if id then
            rednet.send(id, { app = "AurumGame", game = mode, join = os.getComputerID() }, GAME_PROTOCOL)
            status = "Join request sent to " .. tostring(id)
        else
            status = "Hosting as ID " .. tostring(os.getComputerID())
        end
    end
    while true do
        draw()
        local event = { ctx.pullEvent() }
        if event[1] == "mouse_click" then
            local _, _, x, y = unpack(event)
            if y == 1 then
                if x >= 7 and x <= 12 then difficulty = "easy"
                elseif x >= 14 and x <= 18 then difficulty = "medium"
                elseif x >= 20 and x <= 26 then difficulty = "hard"
                elseif x >= 28 and x <= 31 then difficulty = "hardcore"
                elseif x >= 33 and x <= 40 then online()
                elseif x >= 42 then ctx.close(); return end
            else
                status = "Bot " .. difficulty .. " moved."
            end
        elseif event[1] == "rednet_message" and event[4] == GAME_PROTOCOL then
            status = "Online message from " .. tostring(event[2])
        elseif event[1] == "key" and (event[2] == keys.escape or event[2] == keys.backspace) then ctx.close(); return
        elseif event[1] == "terminate" then ctx.close(); return end
    end
end

local function scanDesktop()
    desktopIcons = {}
    local entries = listSorted(DESKTOP)
    local function iconMetrics()
        if uiSettings.iconSize == "tiny" then
            return 6, 3, 2
        elseif uiSettings.iconSize == "normal" then
            return 10, 4, 3
        elseif uiSettings.iconSize == "large" then
            return 12, 4, 3
        end
        return 7, 3, 2
    end
    local colWidth, rowHeight, iconHeight = iconMetrics()
    local maxCols = max(1, math.floor(W / (colWidth + 1)))
    local index = 0

    for _, entry in ipairs(entries) do
        local name = entry.name
        if name:sub(1, 1) ~= "." then
            index = index + 1
            local col = (index - 1) % maxCols
            local row = math.floor((index - 1) / maxCols)
            local data = {}
            if extension(entry.path) == "link" then
                data = parseLink(entry.path)
            end
            local title = data.title or name:gsub("%.link$", "")
            local icon = data.icon or (entry.dir and "D" or (extension(entry.path):sub(1, 1):upper()))
            if icon == "" then icon = ">" end
            desktopIcons[#desktopIcons + 1] = {
                x = 1 + col * (colWidth + 1),
                y = 2 + row * rowHeight,
                w = colWidth,
                h = iconHeight,
                path = entry.path,
                title = title,
                icon = icon:sub(1, 2),
                target = data.target
            }
        end
    end
end

local function desktopBgAt(y)
    local height = max(1, H - 1)
    local pos = y / height
    local mode = uiSettings.gradient

    if mode == "green" then
        if pos < 0.35 then return colors.lime end
        if pos < 0.7 then return colors.green end
        return colors.blue
    elseif mode == "gray" then
        if pos < 0.35 then return colors.lightGray end
        if pos < 0.7 then return colors.gray end
        return colors.black
    elseif mode == "sunset" then
        if pos < 0.35 then return colors.orange end
        if pos < 0.7 then return colors.red end
        return colors.purple
    end
    if pos < 0.28 then return colors.lightBlue end
    if pos < 0.62 then return colors.cyan end
    return colors.blue
end

local function drawDesktop()
    for y = 1, H - 1 do
        fill(1, y, W, 1, desktopBgAt(y))
    end
    writeAt(2, 1, OS_NAME .. " " .. VERSION, colors.white, desktopBgAt(1))
    writeAt(max(1, W - 18), 1, "ID " .. tostring(os.getComputerID()), colors.white, desktopBgAt(1))

    for _, icon in ipairs(desktopIcons) do
        local selected = selectedIcon == icon.path
        local fg = colors.white
        for row = 0, icon.h - 1 do
            fill(icon.x, icon.y + row, icon.w, 1, selected and palette.selected or desktopBgAt(icon.y + row))
        end
        writeAt(icon.x, icon.y, "[" .. shorten(icon.icon, 2) .. "]", fg, selected and palette.selected or desktopBgAt(icon.y))
        writeAt(icon.x, icon.y + 1, shorten(icon.title, icon.w), fg, selected and palette.selected or desktopBgAt(icon.y + 1))
    end
end

local function controlRanges(win)
    local closeStart = win.x + win.w - 2
    local closeEnd = win.x + win.w - 1
    local minStart = win.x + win.w - 5
    local minEnd = win.x + win.w - 4
    return minStart, minEnd, closeStart, closeEnd
end

local function drawWindowFrame(win)
    if win.minimized then
        return
    end
    repositionClient(win)
    fill(win.x, win.y, win.w, 1, focusedId == win.id and palette.title or palette.titleInactive)
    local bg = focusedId == win.id and palette.title or palette.titleInactive
    local titleWidth = max(1, win.w - 7)
    writeAt(win.x + 1, win.y, shorten(win.title, titleWidth), palette.titleText, bg)
    if win.w >= 8 then
        writeAt(win.x + win.w - 5, win.y, " -", colors.white, bg)
        writeAt(win.x + win.w - 2, win.y, " X", colors.white, colors.red)
    end
    win.term.setVisible(true)
    if win.term.redraw then
        win.term.redraw()
    end
    win.term.setVisible(false)
end

local startTabs = {
    { name = "System", items = {
        { label = "Files", action = function() launchFiles("/") end },
        { label = "Settings", action = function() launchSettings() end },
        { label = "Monitor", action = function() launchMonitor() end },
        { label = "Mixer", action = function() launchMixer() end },
        { label = "BIOS", action = function() launchBios() end },
        { label = "CC Shell", action = function() launchCCShell() end },
        { label = "Reboot", action = function() os.reboot() end },
        { label = "Shutdown", action = function() os.shutdown() end }
    }},
    { name = "Apps", items = {
        { label = "Tiny Market", action = function() launchMarket() end },
        { label = "Share", action = function() launchShare() end },
        { label = "Turtle Remote", action = function() launchTurtleRemote() end },
        { label = "Terminal", action = function() launchTerminal() end },
        { label = "Code Studio", action = function() launchCode() end },
        { label = "Add Icon", action = function() launchAddIcon() end },
        { label = "Programs", action = function() launchFiles(PROGRAMS) end },
        { label = "Desktop", action = function() launchFiles(DESKTOP) end }
    }},
    { name = "Tools", items = {
        { label = "Calc", action = function() launchCalculator() end },
        { label = "Engineer Calc", action = function() launchEngineeringCalc() end },
        { label = "Ballistics", action = function() launchBallistics() end },
        { label = "Sheets", action = function() launchSheets() end },
        { label = "Clock", action = function() launchClock() end },
        { label = "Paint", action = function() launchPaint() end }
    }},
    { name = "Games", items = {
        { label = "Checkers", action = function() launchGames("checkers") end },
        { label = "Chess", action = function() launchGames("chess") end },
        { label = "Puzzle", action = function() launchGames("puzzle") end },
        { label = "Strategy", action = function() launchGames("strategy") end },
        { label = "Online Game", action = function() launchGames("online") end }
    }}
}

local function activeStartItems()
    for _, tab in ipairs(startTabs) do
        if tab.name == startTab then
            return tab.items
        end
    end
    return startTabs[1].items
end

local function drawStartMenu()
    if not menuOpen then
        return
    end
    local width = 24
    local items = activeStartItems()
    local y = H - #items - 2
    writeAt(1, y, pad(" " .. startTab, width), colors.white, colors.blue)
    local tabLine = ""
    for _, tab in ipairs(startTabs) do
        tabLine = tabLine .. tab.name:sub(1, 3) .. " "
    end
    writeAt(1, y + 1, pad(tabLine, width), colors.black, colors.lightGray)
    for i, item in ipairs(items) do
        writeAt(1, y + 1 + i, pad(item.label, width), colors.black, colors.lightGray)
    end
end

local function drawTaskbar()
    fill(1, taskbarY, W, 1, palette.taskbar)
    writeAt(1, taskbarY, " Start ", colors.black, colors.lightGray)
    local clock = minecraftClockText()
    local volume = volumeText()
    local disk = storageText()
    local rightText = disk .. "  " .. volume .. "  " .. clock
    local clockX = max(1, W - #rightText + 1)
    local volumeX = clockX + #disk + 2
    volumeRect = { x = volumeX, w = #volume, y = taskbarY }
    writeAt(clockX, taskbarY, clock, colors.white, palette.taskbar)
    writeAt(clockX, taskbarY, rightText, colors.white, palette.taskbar)
    taskRects = {}
    local x = 9
    for _, win in ipairs(windows) do
        if x > clockX - 3 then
            break
        end
        local label = shorten(win.title, 10)
        local width = min(max(#label + 4, 8), max(0, clockX - x - 1))
        if width < 4 then
            break
        end
        local bg
        if focusedId == win.id and not win.minimized then
            bg = palette.taskbarActive
        elseif win.minimized then
            bg = colors.black
        else
            bg = colors.lightGray
        end
        local fg = bg == colors.lightGray and colors.black or colors.white
        writeAt(x, taskbarY, pad(" " .. label, width - 1) .. "X", fg, bg)
        taskRects[#taskRects + 1] = {
            id = win.id,
            x = x,
            y = taskbarY,
            w = width,
            closeX = x + width - 1
        }
        x = x + width + 1
    end
    trashRect = { x = max(1, W - 8), y = H - 2, w = 8, h = 1 }
    writeAt(trashRect.x, trashRect.y, "[Trash]", colors.white, colors.red)
end

local function redraw()
    W, H = term.getSize()
    taskbarY = H
    scanDesktop()
    drawDesktop()
    for _, win in ipairs(windows) do
        drawWindowFrame(win)
    end
    drawStartMenu()
    drawTaskbar()
    term.setCursorBlink(false)
end

local function hitWindow(x, y)
    for i = #windows, 1, -1 do
        local win = windows[i]
        if not win.minimized and x >= win.x and x <= win.x + win.w - 1 and y >= win.y and y <= win.y + win.h - 1 then
            return win
        end
    end
    return nil
end

local function translateMouse(win, event)
    local name = event[1]
    if name == "mouse_click" or name == "mouse_up" or name == "mouse_drag" then
        return { name, event[2], event[3] - win.x + 1, event[4] - win.y }
    elseif name == "mouse_scroll" then
        return { name, event[2], event[3] - win.x + 1, event[4] - win.y }
    end
    return event
end

local function dispatchToWindow(win, event)
    if win and not win.dead and not win.closeRequested then
        resumeWindow(win, event)
    end
end

local function handleTaskbarClick(x, y)
    if y ~= taskbarY then
        return false
    end
    if x >= 1 and x <= 7 then
        menuOpen = not menuOpen
        return true
    end
    if volumeRect and x >= volumeRect.x and x < volumeRect.x + volumeRect.w then
        local level = math.floor(((x - volumeRect.x + 1) / volumeRect.w) * 100)
        uiSettings.volume = tostring(clamp(level, 0, 100))
        saveSettings()
        playUiSound("click")
        return true
    end
    for _, rect in ipairs(taskRects) do
        if x >= rect.x and x < rect.x + rect.w then
            if x == rect.closeX then
                closeWindow(rect.id)
            else
                local win = findWindow(rect.id)
                if win then
                    if win.minimized then
                        focusWindow(rect.id)
                    elseif focusedId == rect.id then
                        minimizeWindow(rect.id)
                    else
                        focusWindow(rect.id)
                    end
                end
            end
            return true
        end
    end
    return true
end

local function handleMenuClick(x, y)
    if not menuOpen then
        return false
    end
    local width = 24
    local items = activeStartItems()
    local startY = H - #items - 2
    if x >= 1 and x <= width and y == startY + 1 then
        local tabIndex = math.floor((x - 1) / 4) + 1
        if startTabs[tabIndex] then
            startTab = startTabs[tabIndex].name
        end
        return true
    end
    if x >= 1 and x <= width and y > startY + 1 and y < H then
        local item = items[y - startY - 1]
        menuOpen = false
        if item and item.action then
            playUiSound("click")
            item.action()
        end
        return true
    end
    menuOpen = false
    return false
end

local function handleDesktopClick(x, y)
    selectedIcon = nil
    for _, icon in ipairs(desktopIcons) do
        if x >= icon.x and x < icon.x + icon.w and y >= icon.y and y < icon.y + icon.h then
            selectedIcon = icon.path
            desktopDragIcon = icon.path
            desktopDragActive = false
            local now = os.clock()
            if lastIconClick.path == icon.path and now - lastIconClick.time < 0.65 then
                launchPath(icon.target or icon.path)
                desktopDragIcon = nil
            end
            lastIconClick.path = icon.path
            lastIconClick.time = now
            return true
        end
    end
    return false
end

local function handleMouse(event)
    local name = event[1]
    local x, y
    if name == "mouse_scroll" then
        x, y = event[3], event[4]
    else
        x, y = event[3], event[4]
    end

    if name == "mouse_drag" and dragging then
        local win = findWindow(dragging.id)
        if win then
            win.x = x - dragging.dx
            win.y = y - dragging.dy
            clampWindow(win)
            repositionClient(win)
        end
        return
    elseif name == "mouse_drag" and desktopDragIcon then
        desktopDragActive = true
        return
    elseif name == "mouse_up" then
        if desktopDragActive and desktopDragIcon and trashRect and x >= trashRect.x and x < trashRect.x + trashRect.w and y == trashRect.y then
            if fs.exists(desktopDragIcon) and parentPath(desktopDragIcon) == DESKTOP then
                fs.delete(desktopDragIcon)
                selectedIcon = nil
                playUiSound("warn")
            end
        end
        desktopDragIcon = nil
        desktopDragActive = false
        dragging = nil
    end

    if name == "mouse_click" then
        if handleTaskbarClick(x, y) then
            return
        end
        if handleMenuClick(x, y) then
            return
        end
    end

    local win = hitWindow(x, y)
    if win then
        focusWindow(win.id)
        if name == "mouse_click" and y == win.y then
            local minStart, minEnd, closeStart, closeEnd = controlRanges(win)
            if x >= closeStart and x <= closeEnd then
                closeWindow(win.id)
            elseif x >= minStart and x <= minEnd then
                minimizeWindow(win.id)
            else
                dragging = { id = win.id, dx = x - win.x, dy = y - win.y }
            end
            return
        end
        if y > win.y then
            dispatchToWindow(win, translateMouse(win, event))
        end
        return
    end

    if name == "mouse_click" then
        handleDesktopClick(x, y)
    end
end

local function dispatchGlobal(event)
    if event[1] == "timer" or event[1] == "alarm" or event[1] == "term_resize" then
        local copy = {}
        for i, win in ipairs(windows) do copy[i] = win end
        for _, win in ipairs(copy) do
            dispatchToWindow(win, event)
        end
    else
        local win = findWindow(focusedId)
        if win and not win.minimized then
            dispatchToWindow(win, event)
        end
    end
end

local function openLinkTarget(target)
    if target == "builtin:files" then
        launchFiles("/")
        return true
    elseif target == "builtin:terminal" then
        launchTerminal()
        return true
    elseif target == "builtin:share" then
        launchShare()
        return true
    elseif target == "builtin:settings" then
        launchSettings()
        return true
    elseif target == "builtin:calculator" then
        launchCalculator()
        return true
    elseif target == "builtin:paint" then
        launchPaint()
        return true
    elseif target == "builtin:sheets" then
        launchSheets()
        return true
    elseif target == "builtin:clock" then
        launchClock()
        return true
    elseif target == "builtin:code" then
        launchCode()
        return true
    elseif target == "builtin:bios" then
        launchBios()
        return true
    elseif target == "builtin:market" then
        launchMarket()
        return true
    elseif target == "builtin:turtle" then
        launchTurtleRemote()
        return true
    elseif target == "builtin:ballistics" then
        launchBallistics()
        return true
    elseif target == "builtin:engcalc" then
        launchEngineeringCalc()
        return true
    elseif target == "builtin:addicon" then
        launchAddIcon()
        return true
    elseif target == "builtin:monitor" then
        launchMonitor()
        return true
    elseif target == "builtin:mixer" then
        launchMixer()
        return true
    elseif target == "builtin:games" then
        launchGames("checkers")
        return true
    elseif target == "builtin:ccshell" then
        launchCCShell()
        return true
    elseif target == "builtin:programs" then
        launchFiles(PROGRAMS)
        return true
    elseif target == "builtin:desktop" then
        launchFiles(DESKTOP)
        return true
    end
    return false
end

launchFiles = function(path)
    createWindow("Files", min(48, W - 2), min(16, H - 2), function(ctx)
        filesApp(ctx, path or "/")
    end)
end

launchTerminal = function()
    createWindow("Terminal", min(48, W - 2), min(16, H - 2), function(ctx)
        terminalApp(ctx)
    end)
end

launchShare = function()
    createWindow("Share", min(48, W - 2), min(16, H - 2), function(ctx)
        shareApp(ctx)
    end)
end

launchCCShell = function()
    createWindow("CC Shell", min(38, W - 2), min(10, H - 2), function(ctx)
        ccShellApp(ctx)
    end)
end

launchSettings = function()
    createWindow("Settings", min(46, W - 2), min(18, H - 2), function(ctx)
        settingsApp(ctx)
    end)
end

launchCalculator = function()
    createWindow("Calculator", min(26, W - 2), min(16, H - 2), function(ctx)
        calculatorApp(ctx)
    end)
end

launchPaint = function()
    createWindow("Paint", min(52, W - 2), min(18, H - 2), function(ctx)
        paintApp(ctx)
    end)
end

launchSheets = function()
    createWindow("Sheets", min(56, W - 2), min(18, H - 2), function(ctx)
        sheetsApp(ctx)
    end)
end

launchClock = function()
    createWindow("Clock", min(34, W - 2), min(10, H - 2), function(ctx)
        clockApp(ctx)
    end)
end

launchCode = function()
    createWindow("Code Studio", min(58, W - 2), min(18, H - 2), function(ctx)
        codeStudioApp(ctx)
    end)
end

launchBios = function()
    createWindow("BIOS", min(40, W - 2), min(13, H - 2), function(ctx)
        biosApp(ctx)
    end)
end

launchMarket = function()
    createWindow("Tiny Market", min(50, W - 2), min(17, H - 2), function(ctx)
        marketApp(ctx)
    end)
end

launchTurtleRemote = function()
    createWindow("Turtle Remote", min(42, W - 2), min(18, H - 2), function(ctx)
        turtleRemoteApp(ctx)
    end)
end

launchBallistics = function()
    createWindow("Ballistics", min(58, W - 2), min(13, H - 2), function(ctx)
        ballisticsApp(ctx)
    end)
end

launchEngineeringCalc = function()
    createWindow("Engineer Calc", min(42, W - 2), min(12, H - 2), function(ctx)
        engineeringCalcApp(ctx)
    end)
end

launchAddIcon = function()
    createWindow("Add Icon", min(42, W - 2), min(10, H - 2), function(ctx)
        addIconApp(ctx)
    end)
end

launchMonitor = function()
    createWindow("Monitor", min(44, W - 2), min(11, H - 2), function(ctx)
        monitorApp(ctx)
    end)
end

launchMixer = function()
    createWindow("Mixer", min(44, W - 2), min(11, H - 2), function(ctx)
        mixerApp(ctx)
    end)
end

launchDoom = function()
    createWindow("DOOM", min(48, W - 2), min(17, H - 2), function(ctx)
        doomMiniApp(ctx)
    end)
end

launchGames = function(mode)
    createWindow("Games", min(42, W - 2), min(17, H - 2), function(ctx)
        gamesApp(ctx, mode)
    end)
end

launchPath = function(path)
    if not path or path == "" then
        return
    end

    if tostring(path):sub(1, 8) == "builtin:" then
        openLinkTarget(path)
        return
    end

    path = normalizePath(path)
    if not fs.exists(path) then
        return
    end

    if fs.isDir(path) then
        launchFiles(path)
        return
    end

    if extension(path) == "link" then
        local data = parseLink(path)
        if data.target and openLinkTarget(data.target) then
            return
        elseif data.target then
            launchPath(data.target)
            return
        end
    end

    local ext = extension(path)
    if ext == "txt" or ext == "md" or ext == "log" or ext == "cfg" or ext == "dat" then
        createWindow(fs.getName(path), min(50, W - 2), min(16, H - 2), function(ctx)
            textViewerApp(ctx, path)
        end)
    else
        createWindow(fs.getName(path), min(50, W - 2), min(16, H - 2), function(ctx)
            programApp(ctx, path)
        end)
    end
end

local bootChoice = bootSplash()
playUiSound("boot")
if bootChoice == "bios" then
    local biosChoice = biosConsole()
    if biosChoice == "shell" then
        exitToShell = true
    end
end
if not exitToShell then
    loginPrompt()
end
term.setCursorBlink(false)
if not exitToShell then
    redraw()
end

local uiTimer = os.startTimer(1)
local updateTimer = os.startTimer(120)
while not exitToShell do
    local event = { os.pullEventRaw() }
    if event[1] == "timer" and event[2] == uiTimer then
        uiTimer = os.startTimer(1)
    elseif event[1] == "timer" and event[2] == updateTimer then
        updateTimer = os.startTimer(120)
        autoUpdateCheck(true)
    end
    if event[1] == "terminate" then
        dispatchGlobal(event)
    elseif event[1] == "term_resize" then
        W, H = term.getSize()
        taskbarY = H
        for _, win in ipairs(windows) do
            clampWindow(win)
            repositionClient(win)
        end
        dispatchGlobal(event)
    elseif event[1] == "mouse_click" or event[1] == "mouse_drag" or event[1] == "mouse_up" or event[1] == "mouse_scroll" then
        handleMouse(event)
    else
        dispatchGlobal(event)
    end
    if not exitToShell then
        redraw()
    end
end

for _, win in ipairs(windows) do
    win.term.setVisible(false)
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print("AurumOS closed. Native ComputerCraft shell is ready.")
