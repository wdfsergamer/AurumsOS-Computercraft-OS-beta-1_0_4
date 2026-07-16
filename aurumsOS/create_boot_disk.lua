-- AurumOS 1.0.5 Boot Disk Creator
-- Use this script to create a bootable floppy disk with AurumOS

local OS_NAME = "AurumOS"
local VERSION = "1.0.5"
local SOURCE_PATH = "aurumsOS/AurumOS"
local DISK_TARGET = "disk"

local function detectDrive()
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral and peripheral.getType(side) == "drive" then
            return side
        end
    end
    return nil
end

local function copyFile(source, target)
    if not fs.exists(source) then
        return false, "Source not found"
    end
    
    local handle = fs.open(source, "r")
    if not handle then
        return false, "Cannot read source"
    end
    
    local data = handle.readAll()
    handle.close()
    
    local dir = fs.getDir(target)
    if dir and dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local targetHandle = fs.open(target, "w")
    if not targetHandle then
        return false, "Cannot write to target"
    end
    
    targetHandle.write(data)
    targetHandle.close()
    return true
end

local function copyDirectory(source, target)
    if not fs.exists(source) or not fs.isDir(source) then
        return false, "Source directory not found"
    end
    
    if not fs.exists(target) then
        fs.makeDir(target)
    end
    
    for _, name in ipairs(fs.list(source)) do
        local sourcePath = fs.combine(source, name)
        local targetPath = fs.combine(target, name)
        
        if fs.isDir(sourcePath) then
            copyDirectory(sourcePath, targetPath)
        else
            copyFile(sourcePath, targetPath)
        end
    end
    
    return true
end

local function formatDisk(driveSide)
    local drive = peripheral.wrap(driveSide)
    if not drive then
        return false, "Cannot access drive"
    end
    
    if not drive.isDiskPresent() then
        return false, "No disk in drive"
    end
    
    drive.ejectDisk()
    sleep(0.5)
    
    return true
end

-- Main process
local W, H = term.getSize()

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

print("=" .. string.rep("=", 40))
print(OS_NAME .. " " .. VERSION .. " Boot Disk Creator")
print("=" .. string.rep("=", 40))
print("")

-- Check for drive
local driveSide = detectDrive()
if not driveSide then
    print("ERROR: No disk drive found!")
    print("")
    print("Please attach a drive to one of these sides:")
    print("top, bottom, left, right, front, back")
    sleep(5)
    return
end

print("Found disk drive on side: " .. driveSide)
print("")

-- Check for disk
local drive = peripheral.wrap(driveSide)
if not drive or not drive.isDiskPresent() then
    print("ERROR: No disk in drive!")
    print("")
    print("Please insert a floppy disk.")
    sleep(5)
    return
end

print("Disk detected!")
print("")
print("WARNING: This will erase all data on the disk!")
print("Continue? (y/n): ")
local answer = read()
if answer:lower() ~= "y" then
    print("Cancelled.")
    return
end

print("")
print("Formatting disk...")

-- Format disk
local ok, err = formatDisk(driveSide)
if not ok then
    print("ERROR: " .. (err or "Unknown error"))
    sleep(5)
    return
end

print("")
print("Insert a blank disk and press Enter when ready...")
read()

print("")
print("Creating directory structure...")

local requiredDirs = {
    "disk:AurumOS",
    "disk:AurumOS/system",
    "disk:AurumOS/Desktop",
    "disk:AurumOS/Programs",
    "disk:AurumOS/modules"
}

for _, dir in ipairs(requiredDirs) do
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

print("Directories created!")
print("")
print("Copying boot files...")

-- Copy boot files
local filesToCopy = {
    {"aurumsOS/AurumOS/boot.lua", "disk:AurumOS/boot.lua"},
    {"aurumsOS/AurumOS/system/activation.lua", "disk:AurumOS/system/activation.lua"},
    {"aurumsOS/AurumOS/system/terminal.lua", "disk:AurumOS/system/terminal.lua"},
    {"aurumsOS/AurumOS/system/games.lua", "disk:AurumOS/system/games.lua"},
    {"aurumsOS/AurumOS/system/gosdoom.lua", "disk:AurumOS/system/gosdoom.lua"},
    {"aurumsOS/AurumOS/system/graphs_integration.lua", "disk:AurumOS/system/graphs_integration.lua"}
}

local copiedCount = 0
for _, pair in ipairs(filesToCopy) do
    local source, target = pair[1], pair[2]
    if fs.exists(source) then
        local ok, err = copyFile(source, target)
        if ok then
            print("✓ Copied: " .. fs.getName(source))
            copiedCount = copiedCount + 1
        else
            print("✗ Failed: " .. fs.getName(source) .. " (" .. err .. ")")
        end
    else
        print("⚠ Missing: " .. fs.getName(source))
    end
end

print("")
print("Creating boot loader...")

-- Create startup file on disk
local startupContent = [[-- AurumOS 1.0.5 Startup
local bootPath = "disk:AurumOS/boot.lua"
if fs.exists(bootPath) then
    dofile(bootPath)
else
    print("ERROR: Boot file not found!")
    print("This disk may be corrupted.")
end
]]

local startupHandle = fs.open("disk:startup.lua", "w")
if startupHandle then
    startupHandle.write(startupContent)
    startupHandle.close()
    print("✓ Created startup.lua")
else
    print("✗ Failed to create startup.lua")
end

print("")
print("Creating portable launcher...")

-- Create a launcher file
local launcherContent = [[-- Launch AurumOS from this disk
local bootFile = "disk:AurumOS/boot.lua"
if fs.exists(bootFile) then
    dofile(bootFile)
else
    print("ERROR: AurumOS boot files not found on disk!")
end
]]

local launcherHandle = fs.open("disk:AurumOS/launcher.lua", "w")
if launcherHandle then
    launcherHandle.write(launcherContent)
    launcherHandle.close()
    print("✓ Created launcher.lua")
else
    print("✗ Failed to create launcher.lua")
end

print("")
print("Creating boot information file...")

-- Create info file
local infoContent = "AurumOS Version: " .. VERSION .. "\n"
infoContent = infoContent .. "Boot Type: Floppy Disk\n"
infoContent = infoContent .. "Created: " .. os.date() .. "\n"

local infoHandle = fs.open("disk:BOOT_INFO.txt", "w")
if infoHandle then
    infoHandle.write(infoContent)
    infoHandle.close()
    print("✓ Created BOOT_INFO.txt")
end

print("")
print("=" .. string.rep("=", 40))
print("Boot disk creation complete!")
print("=" .. string.rep("=", 40))
print("")
print("To use this disk:")
print("1. Insert the disk into a drive")
print("2. Type: run disk:startup.lua")
print("   OR")
print("3. Reboot the computer (will auto-boot)")
print("")
print("Files copied: " .. copiedCount)
print("")
print("Press any key to exit...")
os.pullEvent("key")
