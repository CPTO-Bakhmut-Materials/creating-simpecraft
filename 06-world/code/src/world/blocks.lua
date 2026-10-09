--- Реєстр типів блоків.
--
-- Ідентифікатор блока — маленьке ціле число в сітці світу (0 = повітря).
-- Для кожного твердого блока вказано файли текстур верхньої, бічних і
-- нижньої граней.

--- @alias BlockId integer 0 — повітря; див. константи нижче.
--- @alias BlockFace "top"|"side"|"bottom"

--- @class BlockDef
--- @field name string
--- @field top string Файл текстури для кожного напрямку грані.
--- @field side string
--- @field bottom string

local Blocks = {}

Blocks.AIR = 0
Blocks.STONE = 1
Blocks.DIRT = 2
Blocks.GRASS = 3

--- @type table<BlockId, BlockDef>
Blocks.defs = {
    [Blocks.STONE] = { name = "stone", top = "stone.png", side = "stone.png", bottom = "stone.png" },
    [Blocks.DIRT] = { name = "dirt", top = "dirt.png", side = "dirt.png", bottom = "dirt.png" },
    [Blocks.GRASS] = { name = "grass", top = "grass_top.png", side = "dirt_grass.png", bottom = "dirt.png" },
}

--- Усі файли текстур, кожен один раз, у порядку шарів масиву текстур
--- (шар = індекс - 1). Будується з Blocks.defs.
--- @type string[]
Blocks.TEXTURES = {}
local layerOfFile = {} --- @type table<string, integer>
for _, def in ipairs(Blocks.defs) do
    for _, face in ipairs({ "top", "side", "bottom" }) do
        local file = def[face]
        if not layerOfFile[file] then
            layerOfFile[file] = #Blocks.TEXTURES
            Blocks.TEXTURES[#Blocks.TEXTURES + 1] = file
        end
    end
end

--- Шар масиву текстур для грані блока.
--- @param id BlockId Твердий блок.
--- @param face BlockFace
--- @return integer
function Blocks.textureLayer(id, face)
    return layerOfFile[Blocks.defs[id][face]]
end

return Blocks
