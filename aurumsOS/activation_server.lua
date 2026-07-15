local DEFAULT_VERSION = "1.0.4"
local PROTOCOL = "aurumos-activation-v1"

local function fallbackActivation()
    local activation = {}
    activation.version = DEFAULT_VERSION
    activation.universalKey = "AA-AA-AA-AA"

    local alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local secret = "AurumOS.ComputerCraft.activation.v1"

    local function hash(text)
        local value = 5381
        for i = 1, #text do
            value = (value * 33 + string.byte(text, i) + i * 17) % 2147483647
        end
        return value
    end

    local function encode(value, length)
        local out = {}
        for i = 1, length do
            local index = (value % #alphabet) + 1
            out[#out + 1] = alphabet:sub(index, index)
            value = math.floor(value / #alphabet)
        end
        return table.concat(out)
    end

    function activation.makeKey(computerId, version)
        local base = tostring(computerId or 0) .. "|" .. tostring(version or DEFAULT_VERSION) .. "|" .. secret
        local parts = {}
        local rolling = hash(base)
        for i = 1, 4 do
            rolling = hash(base .. "|" .. tostring(i) .. "|" .. tostring(rolling))
            parts[#parts + 1] = encode(rolling, 2)
        end
        return table.concat(parts, "-")
    end

    return activation
end

local function loadActivation()
    local candidates = {
        "/x32/system/activation.lua",
        "/AurumOS/system/activation.lua",
        "AurumOS/system/activation.lua",
        "system/activation.lua"
    }
    for _, path in ipairs(candidates) do
        if fs.exists(path) then
            local ok, module = pcall(dofile, path)
            if ok and module and module.makeKey then
                return module
            end
        end
    end
    return fallbackActivation()
end

local function findModem()
    if not peripheral or not rednet then
        return nil
    end
    for _, side in ipairs(redstone.getSides()) do
        if peripheral.getType(side) == "modem" then
            return side
        end
    end
    return nil
end

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local activation = loadActivation()
local modemSide = findModem()

clear()
print("AurumOS activation server")
print("Protocol: " .. PROTOCOL)
print("")

if modemSide then
    rednet.open(modemSide)
    print("Rednet modem: " .. modemSide)
else
    print("Rednet modem: not found")
end

print("Manual mode: enter client Computer ID.")
print("Use empty ID to wait for a rednet request, or q to exit.")
print("")

while true do
    write("Client ID: ")
    local input = read()
    input = tostring(input or "")

    if input:lower() == "q" or input:lower() == "quit" or input:lower() == "exit" then
        break
    end

    if input == "" then
        if not modemSide then
            print("No modem is open.")
        else
            print("Waiting for activation request...")
            local sender, message = rednet.receive(PROTOCOL)
            local version = DEFAULT_VERSION
            if type(message) == "table" and message.version then
                version = tostring(message.version)
            elseif type(message) == "string" and message ~= "" then
                version = message
            end
            local key = activation.makeKey(sender, version)
            print("Computer " .. tostring(sender) .. " version " .. version)
            print("Key: " .. key)
            rednet.send(sender, { ok = true, version = version, key = key }, PROTOCOL)
        end
    else
        local computerId = tonumber(input)
        if not computerId then
            print("ID must be a number.")
        else
            write("Version [" .. DEFAULT_VERSION .. "]: ")
            local version = read()
            if version == "" then
                version = DEFAULT_VERSION
            end
            print("Key: " .. activation.makeKey(computerId, version))
        end
    end
    print("")
end
