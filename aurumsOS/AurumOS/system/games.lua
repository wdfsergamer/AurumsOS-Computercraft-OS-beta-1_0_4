-- Games Manager for AurumOS 1.0.5
-- Full implementation of retro games

local games = {}

function games.pong(ctx)
    local t = ctx.term
    local W, H = t.getSize()
    
    local paddleL = math.floor(H / 2)
    local paddleR = math.floor(H / 2)
    local ballX = math.floor(W / 2)
    local ballY = math.floor(H / 2)
    local ballDX = 1
    local ballDY = 1
    local scoreL = 0
    local scoreR = 0
    local running = true
    
    t.setBackgroundColor(colors.black)
    t.setTextColor(colors.white)
    t.clear()
    
    local timer = os.startTimer(0.05)
    
    while running and not ctx.window.closeRequested do
        -- Draw game
        t.clear()
        t.setCursorPos(1, 1)
        t.write("PONG - " .. scoreL .. " vs " .. scoreR)
        
        -- Draw paddles
        for y = 1, H do
            if y == paddleL then
                t.setCursorPos(1, y)
                t.setTextColor(colors.lime)
                t.write("|")
            end
            if y == paddleR then
                t.setCursorPos(W, y)
                t.setTextColor(colors.red)
                t.write("|")
            end
        end
        
        -- Draw ball
        t.setCursorPos(ballX, ballY)
        t.setTextColor(colors.yellow)
        t.write("O")
        
        -- Update ball
        ballX = ballX + ballDX
        ballY = ballY + ballDY
        
        if ballY <= 1 or ballY >= H then ballDY = -ballDY end
        
        if ballX == 2 and (ballY == paddleL or ballY == paddleL - 1 or ballY == paddleL + 1) then
            ballDX = 1
            scoreL = scoreL + 1
        end
        
        if ballX == W - 1 and (ballY == paddleR or ballY == paddleR - 1 or ballY == paddleR + 1) then
            ballDX = -1
            scoreR = scoreR + 1
        end
        
        if ballX < 1 or ballX > W then
            ballX = math.floor(W / 2)
            ballY = math.floor(H / 2)
        end
        
        local event, key = ctx.pullEvent()
        if event == "key" then
            if key == keys.w and paddleL > 2 then paddleL = paddleL - 1
            elseif key == keys.s and paddleL < H - 1 then paddleL = paddleL + 1
            elseif key == keys.up and paddleR > 2 then paddleR = paddleR - 1
            elseif key == keys.down and paddleR < H - 1 then paddleR = paddleR + 1
            elseif key == keys.q then running = false
            end
        end
    end
    
    t.clear()
    t.setCursorPos(1, 1)
    t.write("Final Score: " .. scoreL .. " - " .. scoreR)
end

function games.snake(ctx)
    local t = ctx.term
    local W, H = t.getSize()
    
    local snake = {{x = 10, y = 5}}
    local food = {x = 15, y = 5}
    local dx = 1
    local dy = 0
    local growing = false
    local score = 0
    local running = true
    
    t.setBackgroundColor(colors.black)
    t.setTextColor(colors.white)
    t.clear()
    
    while running and not ctx.window.closeRequested do
        t.clear()
        t.setCursorPos(1, 1)
        t.write("SNAKE - Score: " .. score)
        
        -- Draw snake
        t.setTextColor(colors.lime)
        for _, segment in ipairs(snake) do
            if segment.x >= 1 and segment.x <= W and segment.y >= 2 and segment.y <= H then
                t.setCursorPos(segment.x, segment.y)
                t.write("#")
            end
        end
        
        -- Draw food
        t.setTextColor(colors.red)
        t.setCursorPos(food.x, food.y)
        t.write("*")
        
        -- Update snake
        local head = {x = snake[1].x + dx, y = snake[1].y + dy}
        table.insert(snake, 1, head)
        
        if not growing then
            table.remove(snake)
        else
            growing = false
        end
        
        -- Check food collision
        if head.x == food.x and head.y == food.y then
            growing = true
            score = score + 10
            food = {x = math.random(1, W), y = math.random(2, H)}
        end
        
        -- Check wall collision
        if head.x < 1 or head.x > W or head.y < 2 or head.y > H then
            running = false
        end
        
        -- Check self collision
        for i = 2, #snake do
            if head.x == snake[i].x and head.y == snake[i].y then
                running = false
                break
            end
        end
        
        local event, key = ctx.pullEvent()
        if event == "key" then
            if key == keys.up and dy == 0 then dx = 0; dy = -1
            elseif key == keys.down and dy == 0 then dx = 0; dy = 1
            elseif key == keys.left and dx == 0 then dx = -1; dy = 0
            elseif key == keys.right and dx == 0 then dx = 1; dy = 0
            elseif key == keys.q then running = false
            end
        end
    end
    
    t.clear()
    t.setCursorPos(1, 1)
    t.write("Game Over! Final Score: " .. score)
end

return games
