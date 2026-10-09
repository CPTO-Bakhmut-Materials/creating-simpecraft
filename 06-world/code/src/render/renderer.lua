--- Малює світ однією сіткою.

local Blocks = require("src.world.blocks")
local Mesher = require("src.render.mesher")

--- @class Renderer
--- @field shader love.Shader
--- @field textures love.Image Масив текстур, шар на кожен файл з Blocks.TEXTURES.
--- @field mesh love.Mesh?
--- @field triangleCount integer
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
--- @return Renderer
function Renderer.new(world, textureDir)
    local paths = {}
    for i, name in ipairs(Blocks.TEXTURES) do
        paths[i] = textureDir .. "/" .. name
    end
    local textures = love.graphics.newArrayImage(paths, { mipmaps = true })
    textures:setFilter("linear", "nearest")
    textures:setMipmapFilter("linear")

    local vertices = Mesher.buildWorld(world)
    local mesh = love.graphics.newMesh(VERTEX_FORMAT, vertices, "triangles", "static")
    mesh:setTexture(textures)

    return setmetatable({
        shader = love.graphics.newShader(PIXEL_SHADER, VERTEX_SHADER),
        textures = textures,
        mesh = mesh,
        triangleCount = #vertices / 3,
    }, Renderer)
end

--- @param viewProjection Mat4
function Renderer:draw(viewProjection)
    love.graphics.push("all")
    love.graphics.setShader(self.shader)
    self.shader:send("viewProjection", "row", viewProjection)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.draw(self.mesh)
    love.graphics.pop()
end

return Renderer
