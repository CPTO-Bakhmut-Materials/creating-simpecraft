--- Проходження променя крізь сітку вокселів (Amanatides & Woo,
-- «A Fast Voxel Traversal Algorithm», 1987).
--
-- Промінь відвідує блоки по черзі: на кожному кроці він переходить у
-- наступний блок уздовж тієї осі, межа якої найближча.

local Vec3 = require("src.math.vec3")

--- @class RaycastHit
--- @field block Vec3 Цілі координати блока, у який влучив промінь.
--- @field normal Vec3 Нормаль грані, крізь яку промінь увійшов у блок; нульова,
---   якщо промінь почався всередині твердого блока.

local Raycast = {}

--- @param value number
--- @return integer -1, 0 або 1
local function sign(value)
    return value > 0 and 1 or (value < 0 and -1 or 0)
end

--- Знаходить перший твердий блок уздовж променя.
--- @param isSolid fun(block: Vec3): boolean
--- @param origin Vec3
--- @param direction Vec3 Одиничний, щоб `maxDistance` вимірювалася в блоках.
--- @param maxDistance number
--- @return RaycastHit? hit nil, якщо в межах `maxDistance` нічого твердого немає.
function Raycast.cast(isSolid, origin, direction, maxDistance)
    local block = origin:floor()
    -- У який бік рухається промінь по кожній осі.
    local step = Vec3.fromAxes(function(axis) return sign(direction[axis]) end)
    -- Відстань уздовж променя між двома межами блоків по кожній осі
    -- (нескінченність, якщо промінь паралельний цим межам).
    local boundarySpacing = Vec3.fromAxes(function(axis) return math.abs(1 / direction[axis]) end)
    -- Відстань уздовж променя до найближчої межі блока по кожній осі.
    local nextBoundary = Vec3.fromAxes(function(axis)
        if step[axis] == 0 then
            return math.huge
        end
        local boundary = block[axis] + (step[axis] > 0 and 1 or 0)
        return (boundary - origin[axis]) / direction[axis]
    end)

    local normal = Vec3.ZERO
    local distance = 0
    while distance <= maxDistance do
        if isSolid(block) then
            return { block = block, normal = normal }
        end
        local axis = nextBoundary:smallestAxis()
        distance = nextBoundary[axis]
        block = block + Vec3.unit(axis) * step[axis]
        normal = Vec3.unit(axis) * -step[axis] -- грань, у яку ввійшли, дивиться назад, проти кроку
        nextBoundary = nextBoundary + Vec3.unit(axis) * boundarySpacing[axis]
    end
    return nil
end

return Raycast
