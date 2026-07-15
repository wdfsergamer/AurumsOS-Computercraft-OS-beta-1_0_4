local activation = {}

activation.version = "1.0.4"
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

local function cleanKey(key)
    key = tostring(key or ""):upper()
    key = key:gsub("%s+", "")
    return key
end

function activation.makeKey(computerId, version)
    local base = tostring(computerId or 0) .. "|" .. tostring(version or activation.version) .. "|" .. secret
    local parts = {}
    local rolling = hash(base)
    for i = 1, 4 do
        rolling = hash(base .. "|" .. tostring(i) .. "|" .. tostring(rolling))
        parts[#parts + 1] = encode(rolling, 2)
    end
    return table.concat(parts, "-")
end

function activation.makeToken(computerId, version, key)
    return tostring(hash(tostring(computerId) .. "|" .. tostring(version) .. "|" .. cleanKey(key) .. "|" .. secret))
end

function activation.isValidKey(computerId, version, key)
    key = cleanKey(key)
    if key == activation.universalKey then
        return true, "universal"
    end
    if key == activation.makeKey(computerId, version) then
        return true, "server"
    end
    return false, "bad_key"
end

local function parseData(text)
    local data = {}
    for line in tostring(text or ""):gmatch("[^\r\n]+") do
        local k, v = line:match("^([%w_]+)=(.*)$")
        if k then
            data[k] = v
        end
    end
    return data
end

function activation.readFile(path)
    if not fs.exists(path) then
        return nil
    end
    local handle = fs.open(path, "r")
    if not handle then
        return nil
    end
    local text = handle.readAll()
    handle.close()
    return parseData(text)
end

function activation.writeFile(path, computerId, version, key, method)
    local dir = fs.getDir(path)
    if dir and dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    local token = activation.makeToken(computerId, version, key)
    local handle = fs.open(path, "w")
    handle.writeLine("activated=true")
    handle.writeLine("computer=" .. tostring(computerId))
    handle.writeLine("version=" .. tostring(version))
    handle.writeLine("method=" .. tostring(method or "server"))
    handle.writeLine("token=" .. token)
    handle.close()
end

function activation.isActivated(root, version)
    local path = fs.combine(root, "system/activation.dat")
    local data = activation.readFile(path)
    if not data or data.activated ~= "true" then
        return false
    end

    local computerId = os.getComputerID()
    if tostring(data.computer) ~= tostring(computerId) then
        return false
    end
    local activatedVersion = tostring(data.version or version or activation.version)

    local key
    if data.method == "universal" then
        key = activation.universalKey
    else
        key = activation.makeKey(computerId, activatedVersion)
    end

    return data.token == activation.makeToken(computerId, activatedVersion, key)
end

return activation
