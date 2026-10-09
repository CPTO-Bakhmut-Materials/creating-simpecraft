--- Завантажує світ з файлу MagicaVoxel .vox: читає його, розбирає (див.
-- src/world/vox.lua) і перетворює першу модель на World, обираючи для кольору
-- кожного вокселя тип блока з найближчим еталонним кольором (Blocks.fromColor).

local Blocks = require("src.world.blocks")
local Vox = require("src.world.vox")
local World = require("src.world.world")

local WorldLoader = {}

--- Читає файл з теки гри, а якщо його там немає — зі звичайної файлової
--- системи, щоб світ можна було передати в командному рядку.
--- @param path string
--- @return string
local function readFile(path)
    if love.filesystem.getInfo(path, "file") then
        return assert(love.filesystem.read(path))
    end
    local file, err = io.open(path, "rb")
    if not file then
        error(("cannot open world file: %s"):format(err), 0)
    end
    local data = file:read("*a")
    file:close()
    return data
end

--- Будує світ з розібраного файлу .vox, використовуючи першу модель.
--- @param vox VoxFile
--- @return World
function WorldLoader.fromVox(vox)
    if not vox.palette then
        error("world file has no color palette (RGBA chunk)", 0)
    end
    -- Колір -> блок обчислюємо один раз на індекс палітри, а не на кожен воксель.
    local blockForIndex = {}
    for index, color in ipairs(vox.palette) do
        blockForIndex[index] = Blocks.fromColor(color[1], color[2], color[3])
    end

    local model = vox.models[1]
    local world = World.new(model.size)
    for _, voxel in ipairs(model.voxels) do
        world:set(voxel.position, blockForIndex[voxel.colorIndex] or Blocks.STONE)
    end
    return world
end

--- Завантажує світ з файлу .vox. При невдачі видає зрозумілу помилку.
--- @param path string
--- @return World
function WorldLoader.load(path)
    local ok, result = pcall(function()
        local vox = Vox.parse(readFile(path))
        if #vox.models > 1 then
            print(("warning: '%s' has %d models; only the first is loaded"):format(path, #vox.models))
        end
        return WorldLoader.fromVox(vox)
    end)
    if not ok then
        error(("Failed to load world '%s':\n%s"):format(path, result), 0)
    end
    return result
end

return WorldLoader
