-- GOSDOOM - Simplified DOOM Easter Egg for AurumOS 1.0.5
-- Type 'GOSDOOM' in terminal to launch

local W, H = term.getSize()
local running = true
local player = {
    x = math.floor(W / 2),
    y = math.floor(H / 2),
    health = 100,
    ammo = 30
}

local enemies = {}
local projectiles = {}
local score = 0
local level = 1
local gameTime = 0

-- Spawn initial enemies
local function spawnEnemies(count)
    for i = 1, count do
        table.insert(enemies, {
            x = math.random(1, W),
            y = math.random(2, H - 3),
            health = 1 + level,
            char = "M"
        })
    end
end

local function drawFrame()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    
    -- Draw border
    for x = 1, W do
        term.setCursorPos(x, 1)
        term.write("=")
        term.setCursorPos(x, H - 1)
        term.write("=")
    end
    
    -- Draw stats
    term.setCursorPos(1, H)
    term.write("HP:" .. player.health .. " AMMO:" .. player.ammo .. " SCORE:" .. score)
    
    -- Draw player
    term.setCursorPos(player.x, player.y)
    term.setTextColor(colors.lime)
    term.write("@")
    
    -- Draw enemies
    term.setTextColor(colors.red)
    for _, enemy in ipairs(enemies) do
        if enemy.x >= 1 and enemy.x <= W and enemy.y >= 2 and enemy.y <= H - 2 then
            term.setCursorPos(enemy.x, enemy.y)
            term.write(enemy.char)
        end
    end
    
    -- Draw projectiles
    term.setTextColor(colors.yellow)
    for _, proj in ipairs(projectiles) do
        if proj.x >= 1 and proj.x <= W and proj.y >= 2 and proj.y <= H - 2 then
            term.setCursorPos(proj.x, proj.y)
            term.write(".")
        end
    end
end

local function moveEnemies()
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if math.random() > 0.5 then
            if player.x > enemy.x then enemy.x = enemy.x + 1
            else enemy.x = enemy.x - 1 end
        end
        if math.random() > 0.7 then
            if player.y > enemy.y then enemy.y = enemy.y + 1
            else enemy.y = enemy.y - 1 end
        end
        
        if enemy.x <= 1 then enemy.x = 1 end
        if enemy.x >= W then enemy.x = W end
        if enemy.y <= 2 then enemy.y = 2 end
        if enemy.y >= H - 2 then enemy.y = H - 2 end
        
        if math.abs(enemy.x - player.x) < 2 and math.abs(enemy.y - player.y) < 2 then
            player.health = player.health - 1
            if player.health <= 0 then running = false end
        end
    end
end

local function updateProjectiles()
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        proj.x = proj.x + proj.dx
        proj.y = proj.y + proj.dy
        
        if proj.x < 1 or proj.x > W or proj.y < 2 or proj.y > H - 2 then
            table.remove(projectiles, i)
        else
            for j = #enemies, 1, -1 do
                local enemy = enemies[j]
                if math.abs(proj.x - enemy.x) < 1 and math.abs(proj.y - enemy.y) < 1 then
                    enemy.health = enemy.health - 1
                    if enemy.health <= 0 then
                        table.remove(enemies, j)
                        score = score + 100 * level
                    end
                    table.remove(projectiles, i)
                    break
                end
            end
        end
    end
end

local function shoot(dirX, dirY)
    if player.ammo > 0 then
        player.ammo = player.ammo - 1
        table.insert(projectiles, {
            x = player.x,
            y = player.y,
            dx = dirX,
            dy = dirY
        })
    end
end

term.clear()
spawnEnemies(3 + level)

local timer = os.startTimer(0.1)

while running do
    drawFrame()
    moveEnemies()
    updateProjectiles()
    gameTime = gameTime + 1
    
    if #enemies == 0 then
        level = level + 1
        score = score + 500
        spawnEnemies(3 + level)
    end
    
    local event = {os.pullEventRaw()}
    if event[1] == "key" then
        if event[2] == keys.w then player.y = math.max(2, player.y - 1)
        elseif event[2] == keys.s then player.y = math.min(H - 2, player.y + 1)
        elseif event[2] == keys.a then player.x = math.max(1, player.x - 1)
        elseif event[2] == keys.d then player.x = math.min(W, player.x + 1)
        elseif event[2] == keys.up then shoot(0, -1)
        elseif event[2] == keys.down then shoot(0, 1)
        elseif event[2] == keys.left then shoot(-1, 0)
        elseif event[2] == keys.right then shoot(1, 0)
        elseif event[2] == keys.q then running = false
        end
    elseif event[1] == "terminate" then
        running = false
    end
    
    if gameTime % 20 == 0 and player.ammo < 30 then
        player.ammo = player.ammo + 1
    end
end

term.clear()
term.setCursorPos(1, 1)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
print("=== GAME OVER ===")
print("Final Score: " .. score)
print("Level Reached: " .. level)
print("\nPress any key to return...")
os.pullEvent("key")
