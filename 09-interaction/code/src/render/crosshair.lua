--- Приціл у центрі екрана: позначає блок, який ламатимемо чи до якого ставитимемо новий.

local Crosshair = {}

local SIZE = 0.012 -- половина довжини лінії як частка меншої сторони екрана

--- Малює приціл поверх кадру.
function Crosshair.draw()
    local graphics = love.graphics
    local width, height = graphics.getDimensions()
    local cx, cy, size = width / 2, height / 2, math.max(8, SIZE * math.min(width, height))
    graphics.push("all")
    graphics.setLineWidth(2)
    graphics.setColor(1, 1, 1, 0.9)
    graphics.line(cx - size, cy, cx + size, cy)
    graphics.line(cx, cy - size, cx, cy + size)
    graphics.pop()
end

return Crosshair
