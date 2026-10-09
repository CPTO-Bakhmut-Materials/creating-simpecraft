--- Розбір формату MagicaVoxel .vox.
-- Специфікація: https://github.com/ephtracy/voxel-model/blob/master/MagicaVoxel-file-format-vox.txt
--
-- Читаються лише чанки, потрібні для статичного світу з блоків: SIZE, XYZI і
-- RGBA. Чанки сцени, матеріалів і шарів пропускаються. Чистий Lua без LÖVE,
-- тож модуль можна тестувати поза рушієм.

--- @class Voxel
--- @field position Vec3 Цілі координати від 0.
--- @field colorIndex integer Індекс палітри, 1..255.

--- @class VoxModel
--- @field size Extent3
--- @field voxels Voxel[]

--- @class VoxFile
--- @field version integer
--- @field models VoxModel[] Щонайменше одна.
--- @field palette integer[][]? Індекс кольору (1..255) -> `{ r, g, b, a }`; nil, якщо чанка RGBA немає.

local Extent3 = require("src.math.extent3")
local Vec3 = require("src.math.vec3")

local Vox = {}

local HEADER_SIZE = 12 -- id чанка (4) + розмір вмісту (4) + розмір дочірніх чанків (4)

local function fail(message, ...)
    error("vox: " .. message:format(...), 0)
end

--- Чотири байти, молодший перший (little-endian), як ціле без знака.
local function readU32(data, pos)
    local b1, b2, b3, b4 = data:byte(pos, pos + 3)
    if not b4 then
        fail("unexpected end of file at offset %d", pos - 1)
    end
    return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000
end

local function readChunkHeader(data, pos)
    if pos + HEADER_SIZE - 1 > #data then
        fail("truncated chunk header at offset %d", pos - 1)
    end
    local id = data:sub(pos, pos + 3)
    local contentSize = readU32(data, pos + 4)
    local childrenSize = readU32(data, pos + 8)
    if pos + HEADER_SIZE + contentSize + childrenSize - 1 > #data then
        fail("chunk '%s' at offset %d extends past end of file", id, pos - 1)
    end
    return id, contentSize, childrenSize
end

local function readVoxels(data, pos, contentSize)
    local count = readU32(data, pos)
    if 4 + count * 4 > contentSize then
        fail("XYZI chunk declares %d voxels but holds only %d bytes", count, contentSize)
    end
    local voxels = {}
    for i = 0, count - 1 do
        local p = pos + 4 + i * 4
        local x, y, z, colorIndex = data:byte(p, p + 3)
        voxels[#voxels + 1] = { position = Vec3.new(x, y, z), colorIndex = colorIndex }
    end
    return voxels
end

local function readPalette(data, pos)
    -- Запис i чанка (від 0) — це колір індексу палітри i + 1.
    local palette = {}
    for index = 1, 255 do
        local r, g, b, a = data:byte(pos + (index - 1) * 4, pos + (index - 1) * 4 + 3)
        palette[index] = { r, g, b, a }
    end
    return palette
end

--- Розбирає вміст файлу .vox. Видає помилку на пошкоджених даних.
--- @param data string Байти файлу.
--- @return VoxFile
function Vox.parse(data)
    if type(data) ~= "string" or #data < 8 or data:sub(1, 4) ~= "VOX " then
        fail("not a MagicaVoxel file (missing 'VOX ' header)")
    end
    local version = readU32(data, 5)

    local id, contentSize, childrenSize = readChunkHeader(data, 9)
    if id ~= "MAIN" then
        fail("expected MAIN chunk, found '%s'", id)
    end

    local pos = 9 + HEADER_SIZE + contentSize
    local finish = pos + childrenSize
    local models, palette, pendingSize = {}, nil, nil

    while pos < finish do
        id, contentSize, childrenSize = readChunkHeader(data, pos)
        local body = pos + HEADER_SIZE
        if id == "SIZE" then
            pendingSize = Extent3.new(readU32(data, body), readU32(data, body + 4), readU32(data, body + 8))
        elseif id == "XYZI" then
            if not pendingSize then
                fail("XYZI chunk at offset %d has no preceding SIZE chunk", pos - 1)
            end
            models[#models + 1] = { size = pendingSize, voxels = readVoxels(data, body, contentSize) }
            pendingSize = nil
        elseif id == "RGBA" then
            if contentSize < 255 * 4 then
                fail("RGBA chunk is too small (%d bytes)", contentSize)
            end
            palette = readPalette(data, body)
        end
        -- Будь-який інший чанк (nTRN, MATL, LAYR, ...) просто перестрибуємо.
        pos = body + contentSize + childrenSize
    end

    if #models == 0 then
        fail("file contains no models")
    end
    return { version = version, models = models, palette = palette }
end

return Vox
