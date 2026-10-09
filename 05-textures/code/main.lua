--- Урок 5: текстури. Кожна грань куба бере свій шар масиву текстур.
-- Миша — огляд, W A S D — рух, Space / Shift — вгору / вниз, Ctrl — швидше, Esc — вихід.

local Camera = require("src.render.camera")
local Vec3 = require("src.math.vec3")

local MOVE_SPEED = 8
local FAST_MULTIPLIER = 3
local MOUSE_SENSITIVITY = 0.0025
local TEXTURE_DIR = "assets/textures"

-- Текстурна координата тепер має три числа: u, v і номер шару масиву текстур.
local VERTEX_FORMAT = {
    { "VertexPosition", "float", 3 },
    { "VertexTexCoord", "float", 3 },
    { "VertexColor", "byte", 4 },
}

local VERTEX_SHADER = [[
uniform mat4 viewProjection;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    return viewProjection * vertexPosition;
}
]]

-- Піксельний шейдер: бере колір з шару VaryingTexCoord.z масиву текстур
-- і множить на колір вершини (яскравість грані).
local PIXEL_SHADER = [[
uniform ArrayImage MainTex;

void effect() {
    love_PixelColor = Texel(MainTex, VaryingTexCoord.xyz) * VaryingColor;
}
]]

-- Файли текстур; шар масиву = індекс у цій таблиці мінус 1.
local TEXTURES = { "stone.png", "dirt.png", "grass_top.png", "dirt_grass.png" }
local LAYER = {}
for index, file in ipairs(TEXTURES) do
    LAYER[file] = index - 1
end

-- Типи блоків: яка текстура на верхній, бічних і нижній гранях.
local STONE = { top = "stone.png", side = "stone.png", bottom = "stone.png" }
local DIRT = { top = "dirt.png", side = "dirt.png", bottom = "dirt.png" }
local GRASS = { top = "grass_top.png", side = "dirt_grass.png", bottom = "dirt.png" }

-- Грані: кути проти годинникової стрілки ззовні, починаючи з лівого нижнього
-- кута текстури. texture — яка з текстур блока лягає на грань.
local FACES = {
    { texture = "side", shade = 0.8, corners = { { 1, 0, 0 }, { 1, 1, 0 }, { 1, 1, 1 }, { 1, 0, 1 } } }, -- +X
    { texture = "side", shade = 0.8, corners = { { 0, 1, 0 }, { 0, 0, 0 }, { 0, 0, 1 }, { 0, 1, 1 } } }, -- -X
    { texture = "side", shade = 0.65, corners = { { 1, 1, 0 }, { 0, 1, 0 }, { 0, 1, 1 }, { 1, 1, 1 } } }, -- +Y
    { texture = "side", shade = 0.65, corners = { { 0, 0, 0 }, { 1, 0, 0 }, { 1, 0, 1 }, { 0, 0, 1 } } }, -- -Y
    { texture = "top", shade = 1.0, corners = { { 0, 0, 1 }, { 1, 0, 1 }, { 1, 1, 1 }, { 0, 1, 1 } } }, -- +Z
    { texture = "bottom", shade = 0.5, corners = { { 0, 1, 0 }, { 1, 1, 0 }, { 1, 0, 0 }, { 0, 0, 0 } } }, -- -Z
}
-- UV для кутів 1..4: лівий нижній, правий нижній, правий верхній, лівий верхній.
-- У зображенні v = 0 — це ВЕРХНІЙ рядок пікселів.
local CORNER_UV = { { 0, 1 }, { 1, 1 }, { 1, 0 }, { 0, 0 } }
local QUAD_ORDER = { 1, 2, 3, 1, 3, 4 }

local shader, textures, scene, camera
local look = { yaw = 0, pitch = 0 }

local function addCube(vertices, x, y, z, block)
    for _, face in ipairs(FACES) do
        local layer = LAYER[block[face.texture]]
        for _, cornerIndex in ipairs(QUAD_ORDER) do
            local corner, uv = face.corners[cornerIndex], CORNER_UV[cornerIndex]
            vertices[#vertices + 1] = {
                x + corner[1], y + corner[2], z + corner[3],
                uv[1], uv[2], layer,
                face.shade, face.shade, face.shade, 1,
            }
        end
    end
end

--- Острівець: шар каменю, над ним земля і трава, кілька стовпів і земляних горбиків.
local function buildScene()
    local vertices = {}
    for x = 0, 15 do
        for y = 0, 15 do
            addCube(vertices, x, y, 0, STONE)
            addCube(vertices, x, y, 1, DIRT)
            addCube(vertices, x, y, 2, GRASS)
            if x % 5 == 2 and y % 5 == 2 then
                for z = 3, 3 + (x + y) % 4 do
                    addCube(vertices, x, y, z, STONE)
                end
            elseif (x * 7 + y * 3) % 11 == 0 then
                addCube(vertices, x, y, 3, DIRT)
            end
        end
    end
    local mesh = love.graphics.newMesh(VERTEX_FORMAT, vertices, "triangles", "static")
    mesh:setTexture(textures)
    return mesh
end

local function loadTextures()
    local paths = {}
    for i, file in ipairs(TEXTURES) do
        paths[i] = TEXTURE_DIR .. "/" .. file
    end
    local image = love.graphics.newArrayImage(paths, { mipmaps = true })
    image:setFilter("linear", "nearest") -- зменшення плавне, збільшення — чіткі пікселі
    image:setMipmapFilter("linear")
    return image
end

function love.load()
    love.graphics.setBackgroundColor(0.53, 0.75, 0.95)
    shader = love.graphics.newShader(PIXEL_SHADER, VERTEX_SHADER)
    textures = loadTextures()
    scene = buildScene()
    camera = Camera.new(Vec3.new(-3, -3, 8), math.rad(45), math.rad(-25), math.rad(70), 0.05, 1000)
    love.mouse.setRelativeMode(true)
end

local function axis(positiveKey, negativeKey)
    return (love.keyboard.isDown(positiveKey) and 1 or 0) - (love.keyboard.isDown(negativeKey) and 1 or 0)
end

function love.update(dt)
    camera:rotate(look.yaw, look.pitch)
    look.yaw, look.pitch = 0, 0
    local speed = MOVE_SPEED * (love.keyboard.isDown("lctrl") and FAST_MULTIPLIER or 1)
    camera:move(dt, axis("w", "s"), axis("d", "a"), axis("space", "lshift"), speed)
end

function love.draw()
    local width, height = love.graphics.getDimensions()
    love.graphics.push("all")
    love.graphics.setShader(shader)
    shader:send("viewProjection", "row", camera:viewProjection(width / height))
    love.graphics.setDepthMode("lequal", true)
    love.graphics.draw(scene)
    love.graphics.pop()
end

function love.mousemoved(_, _, dx, dy)
    if love.mouse.getRelativeMode() then
        look.yaw = look.yaw - dx * MOUSE_SENSITIVITY
        look.pitch = look.pitch - dy * MOUSE_SENSITIVITY
    end
end

function love.mousepressed()
    love.mouse.setRelativeMode(true)
end

function love.focus(focused)
    if not focused then
        love.mouse.setRelativeMode(false)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
