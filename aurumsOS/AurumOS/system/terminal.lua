-- Terminal Application for AurumOS 1.0.5
-- Full terminal with command support including GOSDOOM easter egg

local function terminal(ctx)
    local t = ctx.term
    local W, H = t.getSize()
    local history = {}
    local historyIndex = 0
    
    t.setBackgroundColor(colors.black)
    t.setTextColor(colors.white)
    t.clear()
    t.setCursorPos(1, 1)
    t.write("AurumOS 1.0.5 Terminal")
    t.setCursorPos(1, 2)
    t.write("Type 'help' for commands")
    t.setCursorPos(1, 3)
    t.write("")
    
    local line = 4
    
    while not ctx.window.closeRequested do
        if line >= H then
            t.scroll(1)
            line = H - 1
        end
        
        t.setCursorPos(1, line)
        t.setTextColor(colors.green)
        t.write("> ")
        t.setTextColor(colors.white)
        
        local input = ""
        local inputX = 3
        
        while true do
            local event, key, _, _, _ = ctx.pullEvent()
            
            if event == "char" then
                input = input .. key
                t.write(key)
            elseif event == "key" then
                if key == keys.enter then
                    t.write("\n")
                    line = line + 1
                    break
                elseif key == keys.backspace then
                    if #input > 0 then
                        input = input:sub(1, -2)
                        local cx, cy = t.getCursorPos()
                        t.setCursorPos(cx - 1, cy)
                        t.write(" ")
                        t.setCursorPos(cx - 1, cy)
                    end
                end
            end
        end
        
        table.insert(history, input)
        historyIndex = #history
        
        -- Process command
        local parts = {}
        for part in input:gmatch("[^%s]+") do
            table.insert(parts, part)
        end
        
        local cmd = (parts[1] or ""):upper()
        
        if cmd == "HELP" then
            t.setTextColor(colors.cyan)
            t.setCursorPos(1, line)
            line = line + 1
            t.write("Commands:")
            t.setCursorPos(1, line)
            line = line + 1
            t.write("GOSDOOM - Play mini DOOM game")
            t.setCursorPos(1, line)
            line = line + 1
            t.write("CLEAR - Clear screen")
            t.setCursorPos(1, line)
            line = line + 1
            t.write("DISK - Show disk usage")
            t.setCursorPos(1, line)
            line = line + 1
            t.write("TIME - Show current time")
            t.setCursorPos(1, line)
            line = line + 1
            t.write("VERSION - Show OS version")
        elseif cmd == "GOSDOOM" then
            t.setTextColor(colors.red)
            t.setCursorPos(1, line)
            line = line + 1
            t.write("Launching GOSDOOM...")
            sleep(1)
            
            -- Save terminal state
            local savedTerm = term.current()
            if fs.exists(ctx.root .. "/system/gosdoom.lua") then
                dofile(ctx.root .. "/system/gosdoom.lua")
            end
            term.redirect(savedTerm)
            
            t.setBackgroundColor(colors.black)
            t.setTextColor(colors.white)
            t.clear()
            t.setCursorPos(1, 1)
            line = 1
        elseif cmd == "CLEAR" then
            t.clear()
            t.setCursorPos(1, 1)
            line = 1
        elseif cmd == "DISK" then
            t.setTextColor(colors.yellow)
            t.setCursorPos(1, line)
            local free = fs.getFreeSpace("/") or 0
            local capacity = fs.getCapacity("/") or 0
            if capacity > 0 then
                local used = capacity - free
                local pct = math.floor((used / capacity) * 100)
                t.write("Disk: " .. pct .. "% used (" .. free .. " free)")
            end
            line = line + 1
        elseif cmd == "TIME" then
            t.setTextColor(colors.yellow)
            t.setCursorPos(1, line)
            local timeText = textutils.formatTime(os.time(), true) or tostring(os.time())
            t.write("Day " .. os.day() .. " - " .. timeText)
            line = line + 1
        elseif cmd == "VERSION" then
            t.setTextColor(colors.yellow)
            t.setCursorPos(1, line)
            t.write("AurumOS 1.0.5 for ComputerCraft")
            line = line + 1
        elseif cmd ~= "" then
            t.setTextColor(colors.red)
            t.setCursorPos(1, line)
            t.write("Unknown command: " .. cmd)
            line = line + 1
        end
        
        t.setTextColor(colors.white)
    end
end

return terminal
