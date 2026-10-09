--- Сітка блоків фіксованого розміру.
--
-- Блоки адресуються цілими позиціями Vec3, вісь Z — вгору. Блок (x, y, z)
-- займає одиничний куб [x, x+1] x [y, y+1] x [z, z+1]. Усе поза сіткою
-- вважається повітрям і не змінюється.

local Blocks = require("src.world.blocks")

--- @class World
--- @field size Extent3 У блоках.
--- @field blocks BlockId[] Плоска сітка; індекс `size:index(block) + 1` (масиви Lua з 1).
local World = {}
World.__index = World

local AIR = Blocks.AIR

--- Створює світ, заповнений повітрям.
--- @param size Extent3
--- @return World
function World.new(size)
    assert(size.x >= 1 and size.y >= 1 and size.z >= 1, "world dimensions must be positive")
    local blocks = {}
    for i = 1, size:volume() do
        blocks[i] = AIR
    end
    return setmetatable({ size = size, blocks = blocks }, World)
end

--- @param block Vec3 Ціла позиція.
--- @return BlockId
function World:get(block)
    if not self.size:contains(block) then
        return AIR
    end
    return self.blocks[self.size:index(block) + 1]
end

--- @param block Vec3 Ціла позиція.
--- @return boolean
function World:isSolid(block)
    return self:get(block) ~= AIR
end

--- Встановлює блок. Повертає true, якщо світ змінився.
--- @param block Vec3 Ціла позиція.
--- @param id BlockId
--- @return boolean
function World:set(block, id)
    if not self.size:contains(block) then
        return false
    end
    local index = self.size:index(block) + 1
    if self.blocks[index] == id then
        return false
    end
    self.blocks[index] = id
    return true
end

return World
