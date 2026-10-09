--- Урок 1: вікно, ігровий цикл і рух квадрата клавішами WASD.

local SPEED = 300 -- пікселів за секунду
local SIZE = 64

local player = { x = 100, y = 100 }

function love.load()
    love.graphics.setBackgroundColor(0.53, 0.75, 0.95) -- колір неба
end

--- @param dt number Секунди, що минули від попереднього кадру.
function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end
    if love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end
    -- Множимо на dt: швидкість не залежить від частоти кадрів.
    player.x = player.x + dx * SPEED * dt
    player.y = player.y + dy * SPEED * dt
end

function love.draw()
    love.graphics.setColor(0.47, 0.33, 0.23) -- колір землі
    love.graphics.rectangle("fill", player.x, player.y, SIZE, SIZE)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(("FPS: %d   x = %.0f   y = %.0f"):format(love.timer.getFPS(), player.x, player.y), 10, 10)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
