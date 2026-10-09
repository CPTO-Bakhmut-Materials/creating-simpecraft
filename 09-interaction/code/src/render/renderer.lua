--- Малює світ: окрема сітка для кожного чанка (куба 16x16x16 блоків).
-- Після зміни блока перебудовуються лише чанки, яких ця зміна стосується.

local Blocks = require("src.world.blocks")
local Mesher = require("src.render.mesher")
local Vec3 = require("src.math.vec3")

--- @class Renderer
--- @field world World
--- @field chunkSize integer Ребро чанка в блоках.
--- @field chunks Extent3 Розмір світу в чанках; ключ чанка — `chunks:index(chunk)`.
--- @field shader love.Shader
--- @field textures love.Image Масив текстур, шар на кожен файл з Blocks.TEXTURES.
--- @field meshes table<integer, love.Mesh> Ключ чанка -> сітка (порожніх чанків немає).
--- @field dirty table<integer, true> Ключі чанків, які треба перебудувати при наступному update.
local Renderer = {}
Renderer.__index = Renderer

local VERTEX_FORMAT = {
    { "VertexPosition", "float", 3 },
    { "VertexTexCoord", "float", 3 }, -- u, v, шар масиву текстур
    { "VertexColor", "byte", 4 },
}

local VERTEX_SHADER = [[
uniform mat4 viewProjection;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    return viewProjection * vertexPosition;
}
]]

local PIXEL_SHADER = [[
uniform ArrayImage MainTex;

void effect() {
    love_PixelColor = Texel(MainTex, VaryingTexCoord.xyz) * VaryingColor;
}
]]

--- @param world World
--- @param textureDir string Тека з файлами Blocks.TEXTURES.
--- @param chunkSize integer
--- @return Renderer
function Renderer.new(world, textureDir, chunkSize)
    local paths = {}
    for i, name in ipairs(Blocks.TEXTURES) do
        paths[i] = textureDir .. "/" .. name
    end
    local textures = love.graphics.newArrayImage(paths, { mipmaps = true })
    textures:setFilter("linear", "nearest")
    textures:setMipmapFilter("linear")

    local self = setmetatable({
        world = world,
        chunkSize = chunkSize,
        chunks = world.size:divideRoundingUp(chunkSize),
        shader = love.graphics.newShader(PIXEL_SHADER, VERTEX_SHADER),
        textures = textures,
        meshes = {},
        dirty = {},
    }, Renderer)

    for key = 0, self.chunks:volume() - 1 do
        self.dirty[key] = true
    end
    return self
end

--- Ставить чанк у чергу на перебудову; чанки поза світом ігноруються.
--- @param chunk Vec3 Координати чанка (координати блока / розмір чанка).
function Renderer:markChunkDirty(chunk)
    if self.chunks:contains(chunk) then
        self.dirty[self.chunks:index(chunk)] = true
    end
end

--- Чанки, сітки яких можуть змінитися, коли змінюється `block`: його власний чанк
--- і кожен сусідній чанк, з яким блок має спільну грань (якщо блок лежить на межі
--- чанка, грань сусіда, повернута до нього, може з'явитися або зникнути).
--- Може повернути й чанки поза світом.
--- @param block Vec3 Цілі координати блока.
--- @param chunkSize integer
--- @return Vec3[] Координати чанків.
function Renderer.chunksTouching(block, chunkSize)
    local chunk = (block / chunkSize):floor()
    local inChunk = block - chunk * chunkSize -- 0..chunkSize-1 по кожній осі
    local chunks = { chunk }
    for _, axis in ipairs(Vec3.AXES) do
        if inChunk[axis] == 0 then
            chunks[#chunks + 1] = chunk - Vec3.unit(axis)
        end
        if inChunk[axis] == chunkSize - 1 then
            chunks[#chunks + 1] = chunk + Vec3.unit(axis)
        end
    end
    return chunks
end

--- Викликайте після зміни блока `block`, щоб перебудувати потрібні чанки.
--- @param block Vec3 Цілі координати блока.
function Renderer:blockChanged(block)
    for _, chunk in ipairs(Renderer.chunksTouching(block, self.chunkSize)) do
        self:markChunkDirty(chunk)
    end
end

--- @param key integer Див. Renderer.chunks.
function Renderer:rebuildChunk(key)
    local chunk = self.chunks:cell(key)
    local size = self.chunkSize

    if self.meshes[key] then
        self.meshes[key]:release() -- звільняємо пам'ять відеокарти одразу, не чекаючи збирача сміття
        self.meshes[key] = nil
    end
    local vertices = Mesher.buildChunk(self.world, chunk * size, size)
    if #vertices > 0 then
        local mesh = love.graphics.newMesh(VERTEX_FORMAT, vertices, "triangles", "static")
        mesh:setTexture(self.textures)
        self.meshes[key] = mesh
    end
end

--- Перебудовує всі чанки, позначені з минулого update.
function Renderer:update()
    for key in pairs(self.dirty) do
        self:rebuildChunk(key)
    end
    self.dirty = {}
end

--- @param viewProjection Mat4
function Renderer:draw(viewProjection)
    love.graphics.push("all")
    love.graphics.setShader(self.shader)
    self.shader:send("viewProjection", "row", viewProjection)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setMeshCullMode("back") -- не малювати трикутники, повернуті до нас спиною
    for _, mesh in pairs(self.meshes) do
        love.graphics.draw(mesh)
    end
    love.graphics.pop()
end

return Renderer
