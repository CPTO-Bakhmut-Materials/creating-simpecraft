--- Малює світ: окрема сітка для кожного чанка (куба 16x16x16 блоків).

local Blocks = require("src.world.blocks")
local Mesher = require("src.render.mesher")

--- @class Renderer
--- @field world World
--- @field chunkSize integer Ребро чанка в блоках.
--- @field chunks Extent3 Розмір світу в чанках; ключ чанка — `chunks:index(chunk)`.
--- @field shader love.Shader
--- @field textures love.Image Масив текстур, шар на кожен файл з Blocks.TEXTURES.
--- @field meshes table<integer, love.Mesh> Ключ чанка -> сітка (порожніх чанків немає).
--- @field triangleCount integer
--- @field meshCount integer
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
        triangleCount = 0,
        meshCount = 0,
    }, Renderer)

    for key = 0, self.chunks:volume() - 1 do
        self:buildChunk(key)
    end
    return self
end

--- @param key integer Див. Renderer.chunks.
function Renderer:buildChunk(key)
    local chunk = self.chunks:cell(key)
    local vertices = Mesher.buildChunk(self.world, chunk * self.chunkSize, self.chunkSize)
    if #vertices > 0 then
        local mesh = love.graphics.newMesh(VERTEX_FORMAT, vertices, "triangles", "static")
        mesh:setTexture(self.textures)
        self.meshes[key] = mesh
        self.triangleCount = self.triangleCount + #vertices / 3
        self.meshCount = self.meshCount + 1
    end
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
