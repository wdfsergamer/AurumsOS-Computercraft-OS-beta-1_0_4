local VERSION = "1.0.4"
local MIN_WIDE_PC_WIDTH = 40

local w, h = term.getSize()
term.clear()
term.setCursorPos(1, 1)
print("AurumOS portable installer")
print("Version " .. VERSION)
print("Screen: " .. tostring(w) .. "x" .. tostring(h))
print("")

if w >= MIN_WIDE_PC_WIDTH then
    print("Portable mode is for pocket/portable computers only.")
    print("This screen is wide enough to look like a block PC.")
    print("Use install.lua instead.")
    return
end

if not fs.exists("install.lua") then
    print("install.lua not found next to portable_install.lua.")
    return
end

print("Portable screen detected.")
print("Installing normal AurumOS with compact defaults.")
print("")

if fs.exists("AurumOS/system/settings.lua") then
    print("Settings source detected.")
end

shell.run("install.lua")
