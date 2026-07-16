-- Activation system for AurumOS 1.0.5

local activation = {}

function activation.isActivated(root, version)
    local activationFile = fs.combine(root, "system/activation.key")
    if not fs.exists(activationFile) then
        return false
    end
    
    local handle = fs.open(activationFile, "r")
    if not handle then return false end
    
    local data = handle.readAll()
    handle.close()
    
    local computerId = os.getComputerID()
    local expectedKey = "AURUMKEY-" .. computerId .. "-" .. version
    
    return data:find(expectedKey) ~= nil
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
