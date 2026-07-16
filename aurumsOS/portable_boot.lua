-- AurumOS 1.0.5 Portable Boot
-- This file can be placed on a floppy disk for portable booting
-- Run this to boot AurumOS from the disk

local DISK_PATH = "/disk"
local BOOT_FILE = "disk:AurumOS/boot.lua"
local OS_NAME = "AurumOS"
local VERSION = "1.0.5"

local function isBootFromDisk()
    return fs.exists(BOOT_FILE)
end

local function detectDrive()
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral and peripheral.getType(side) == "drive" then
            local drive = peripheral.wrap(side)
            if drive and drive.isDiskPresent() then
                return side, drive
            end
        end
    end
    return nil, nil
end

local function bootSplash()
    term.setCursorBlink(false)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    local W, H = term.getSize()
    local title = "AurumOS 1.0.5 Boot Loader"
    local hint = "Booting from disk..."
    term.setCursorPos(math.max(1, math.floor((W - #title) / 2) + 1), math.floor(H / 2) - 2)
    term.write(title)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(math.max(1, math.floor((W - #hint) / 2) + 1), math.floor(H / 2) + 2)
    term.write(hint)
    sleep(1)
end

local function createDiskStructure()
    -- Verify disk structure
    local requiredPaths = {
        "disk:AurumOS",
        "disk:AurumOS/system",
        "disk:AurumOS/Desktop",
        "disk:AurumOS/Programs"
    }
    
    for _, path in ipairs(requiredPaths) do
        if not fs.exists(path) then
            fs.makeDir(path)
        end
    end
end

-- Check for disk
local driveSide, drivePeripheral = detectDrive()

if not driveSide then
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("ERROR: No disk drive detected!")
    print("")
    print("Please attach a drive to one of these sides:")
    print("top, bottom, left, right, front, back")
    print("")
    print("Then insert a disk with AurumOS files.")
    sleep(5)
    return
end

-- Boot sequence
bootSplash()

-- Verify boot files exist on disk
if not fs.exists(BOOT_FILE) then
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("ERROR: Boot files not found on disk!")
    print("")
    print("The disk does not contain AurumOS files.")
    print("")
    print("Please use 'create_boot_disk.lua' to create")
    print("a bootable AurumOS disk.")
    sleep(5)
    return
end

-- Create directory structure on disk if needed
createDiskStructure()

-- Load and execute boot
local bootCode = fs.open(BOOT_FILE, "r")
if not bootCode then
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("ERROR: Cannot read boot.lua!")
    sleep(5)
    return
end

local bootEnv = {
    _G = _ENV,
    term = term,
    os = os,
    fs = fs,
    colors = colors,
    keys = keys,
    math = math,
    string = string,
    table = table,
    peripheral = peripheral,
    rednet = rednet,
    redstone = redstone,
    textutils = textutils,
    window = window,
    sleep = sleep,
    loadfile = loadfile,
    dofile = dofile,
    read = read,
    write = write,
    print = print,
    io = io
}

local bootContent = bootCode.readAll()
bootCode.close()

local bootFunc, err = load(bootContent, "boot.lua", "t", bootEnv)
if not bootFunc then
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("ERROR: Cannot load boot.lua!")
    print(err)
    sleep(5)
    return
end

-- Execute boot
local ok, result = pcall(bootFunc)
if not ok then
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    print("BOOT ERROR!")
    print(result)
    sleep(5)
end
