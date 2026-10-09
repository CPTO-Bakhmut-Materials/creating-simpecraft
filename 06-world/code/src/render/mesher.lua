--- Будує список трикутників для світу.
--
-- ПЕРША, НАЇВНА ВЕРСІЯ: для кожного твердого блока додаються всі шість граней,
-- навіть ті, що притиснуті до сусіднього блока й ніколи не видимі. В уроці 7
-- ми це виправимо. Кожна вершина — `{ x, y, z, u, v, layer, shade, shade, shade, 1 }`.

local Blocks = require("src.world.blocks")
local Vec3 = require("src.math.vec3")

--- @class CubeFace
--- @field normal Vec3 Напрямок назовні з блока.
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

--- Повертає список вершин для всього світу.
--- @param world World
--- @return table[]
function Mesher.buildWorld(world)
    local vertices = {}
    for z = 0, world.size.z - 1 do
        for y = 0, world.size.y - 1 do
            for x = 0, world.size.x - 1 do
                local block = Vec3.new(x, y, z)
                local id = world:get(block)
                if id ~= Blocks.AIR then
                    for _, face in ipairs(FACES) do
                        emitFace(vertices, block, face, Blocks.textureLayer(id, face.texture))
                    end
                end
            end
        end
    end
    return vertices
end

return Mesher
