--- Тимчасовий генератор світу: горбистий острів з каменю, землі й трави та
-- кам'яний стовп. В уроці 8 його замінить завантаження світу з файлу .vox.

local Blocks = require("src.world.blocks")
local Extent3 = require("src.math.extent3")
local Vec3 = require("src.math.vec3")
local World = require("src.world.world")

local Generate = {}

local SIZE = Extent3.new(48, 48, 24)

--- Висота поверхні в стовпчику (x, y): сума кількох синусоїд.
local function surfaceHeight(x, y)
    local h = 10 + 3 * math.sin(x / 6) + 3 * math.cos(y / 7) + 2 * math.sin((x + y) / 9)
    return math.max(4, math.min(SIZE.z - 2, math.floor(h)))
end

--- @return World
function Generate.island()
    local world = World.new(SIZE)
    for x = 0, SIZE.x - 1 do
        for y = 0, SIZE.y - 1 do
            local height = surfaceHeight(x, y)
            for z = 0, height - 1 do
                local block = Blocks.STONE
                if z == height - 1 then
                    block = Blocks.GRASS
                elseif z >= height - 4 then
                    block = Blocks.DIRT
                end
                world:set(Vec3.new(x, y, z), block)
            end
        end
    end
    -- Кам'яний стовп 2x2 до самої стелі світу.
    for z = surfaceHeight(12, 12), SIZE.z - 1 do
        for dx = 0, 1 do
            for dy = 0, 1 do
                world:set(Vec3.new(12 + dx, 12 + dy, z), Blocks.STONE)
            end
        end
    end
    return world
end

return Generate
