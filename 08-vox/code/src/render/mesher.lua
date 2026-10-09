--- Будує списки трикутників для чанків світу.
--
-- Додаються лише грані між твердим блоком і повітрям. Кожна вершина —
-- `{ x, y, z, u, v, layer, shade, shade, shade, 1 }`, як у форматі сітки в
-- src/render/renderer.lua. Трикутники обходяться проти годинникової стрілки,
-- якщо дивитися ззовні блока, тож можна вмикати відсікання задніх граней.

local Blocks = require("src.world.blocks")
local Vec3 = require("src.math.vec3")

--- @class CubeFace
--- @field normal Vec3 Напрямок назовні з блока; сусід за гранню — `block + normal`.
--- @field texture BlockFace Яку з текстур блока бере грань.
--- @field shade number Яскравість, що імітує сонце згори.
--- @field corners Vec3[] Зміщення від мінімального кута блока.

local Mesher = {}

-- Кути перелічено проти годинникової стрілки ззовні, починаючи з лівого
-- нижнього кута текстури.
--- @type CubeFace[]
local FACES = {
    {
        normal = Vec3.new(1, 0, 0), texture = "side", shade = 0.8,
        corners = { Vec3.new(1, 0, 0), Vec3.new(1, 1, 0), Vec3.new(1, 1, 1), Vec3.new(1, 0, 1) },
    },
    {
        normal = Vec3.new(-1, 0, 0), texture = "side", shade = 0.8,
        corners = { Vec3.new(0, 1, 0), Vec3.new(0, 0, 0), Vec3.new(0, 0, 1), Vec3.new(0, 1, 1) },
    },
    {
        normal = Vec3.new(0, 1, 0), texture = "side", shade = 0.65,
        corners = { Vec3.new(1, 1, 0), Vec3.new(0, 1, 0), Vec3.new(0, 1, 1), Vec3.new(1, 1, 1) },
    },
    {
        normal = Vec3.new(0, -1, 0), texture = "side", shade = 0.65,
        corners = { Vec3.new(0, 0, 0), Vec3.new(1, 0, 0), Vec3.new(1, 0, 1), Vec3.new(0, 0, 1) },
    },
    {
        normal = Vec3.new(0, 0, 1), texture = "top", shade = 1.0,
        corners = { Vec3.new(0, 0, 1), Vec3.new(1, 0, 1), Vec3.new(1, 1, 1), Vec3.new(0, 1, 1) },
    },
    {
        normal = Vec3.new(0, 0, -1), texture = "bottom", shade = 0.5,
        corners = { Vec3.new(0, 1, 0), Vec3.new(1, 1, 0), Vec3.new(1, 0, 0), Vec3.new(0, 0, 0) },
    },
}

-- Текстурні координати кутів 1..4 (лівий нижній, правий нижній, правий верхній, лівий верхній).
local CORNER_UV = { { 0, 1 }, { 1, 1 }, { 1, 0 }, { 0, 0 } }

-- Два трикутники на грань зі збереженням обходу кутів.
local QUAD_ORDER = { 1, 2, 3, 1, 3, 4 }

local function emitFace(vertices, block, face, layer)
    local shade = face.shade
    for _, cornerIndex in ipairs(QUAD_ORDER) do
        local position, uv = block + face.corners[cornerIndex], CORNER_UV[cornerIndex]
        vertices[#vertices + 1] = {
            position.x, position.y, position.z,
            uv[1], uv[2], layer,
            shade, shade, shade, 1,
        }
    end
end

--- Повертає вершини для куба блоків з мінімальним кутом `origin` і ребром
--- `size`, обрізаного межами світу. Може бути порожнім.
--- @param world World
--- @param origin Vec3 Мінімальний кут, у блоках.
--- @param size integer
--- @return table[]
function Mesher.buildChunk(world, origin, size)
    local vertices = {}
    local last = Vec3.fromAxes(function(axis) return math.min(origin[axis] + size, world.size[axis]) - 1 end)

    for z = origin.z, last.z do
        for y = origin.y, last.y do
            for x = origin.x, last.x do
                local block = Vec3.new(x, y, z)
                local id = world:get(block)
                if id ~= Blocks.AIR then
                    for _, face in ipairs(FACES) do
                        -- Грань видно, лише якщо за нею повітря.
                        if not world:isSolid(block + face.normal) then
                            emitFace(vertices, block, face, Blocks.textureLayer(id, face.texture))
                        end
                    end
                end
            end
        end
    end
    return vertices
end

return Mesher
