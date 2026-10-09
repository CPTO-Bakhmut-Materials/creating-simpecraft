--- Урок 4: вільна камера. Миша — огляд, W A S D — рух, Space / Shift — вгору / вниз,
-- Ctrl — швидше, Esc — вихід.

local Camera = require("src.render.camera")
local Vec3 = require("src.math.vec3")

local MOVE_SPEED = 8 -- блоків за секунду
local FAST_MULTIPLIER = 3
local MOUSE_SENSITIVITY = 0.0025 -- радіан на піксель руху миші

local VERTEX_FORMAT = {
    { "VertexPosition", "float", 3 },
    { "VertexColor", "byte", 4 },
}

local VERTEX_SHADER = [[
uniform mat4 viewProjection;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    return viewProjection * vertexPosition;
}
]]

-- Грані одиничного куба: кути проти годинникової стрілки, якщо дивитися ззовні.
-- shade — яскравість грані, що імітує освітлення сонцем згори.
local FACES = {
    { shade = 0.8, corners = { { 1, 0, 0 }, { 1, 1, 0 }, { 1, 1, 1 }, { 1, 0, 1 } } }, -- +X
    { shade = 0.8, corners = { { 0, 1, 0 }, { 0, 0, 0 }, { 0, 0, 1 }, { 0, 1, 1 } } }, -- -X
    { shade = 0.65, corners = { { 1, 1, 0 }, { 0, 1, 0 }, { 0, 1, 1 }, { 1, 1, 1 } } }, -- +Y
    { shade = 0.65, corners = { { 0, 0, 0 }, { 1, 0, 0 }, { 1, 0, 1 }, { 0, 0, 1 } } }, -- -Y
    { shade = 1.0, corners = { { 0, 0, 1 }, { 1, 0, 1 }, { 1, 1, 1 }, { 0, 1, 1 } } }, -- +Z
    { shade = 0.5, corners = { { 0, 1, 0 }, { 1, 1, 0 }, { 1, 0, 0 }, { 0, 0, 0 } } }, -- -Z
}
local QUAD_ORDER = { 1, 2, 3, 1, 3, 4 }

local GRASS = { 0.37, 0.62, 0.21 }
local STONE = { 0.49, 0.49, 0.49 }

local shader, scene, camera
local look = { yaw = 0, pitch = 0 } -- рух миші, накопичений з минулого кадру

--- Додає до `vertices` усі 6 граней куба з мінімальним кутом (x, y, z).
local function addCube(vertices, x, y, z, color)
    for _, face in ipairs(FACES) do
        for _, cornerIndex in ipairs(QUAD_ORDER) do
            local corner = face.corners[cornerIndex]
            vertices[#vertices + 1] = {
                x + corner[1], y + corner[2], z + corner[3],
                color[1] * face.shade, color[2] * face.shade, color[3] * face.shade, 1,
            }
        end
    end
end

--- Поле 16x16 з трави та кілька кам'яних стовпів.
local function buildScene()
    local vertices = {}
    for x = 0, 15 do
        for y = 0, 15 do
            addCube(vertices, x, y, 0, GRASS)
            if x % 5 == 2 and y % 5 == 2 then
                for z = 1, 1 + (x + y) % 4 do
                    addCube(vertices, x, y, z, STONE)
                end
            end
        end
    end
    return love.graphics.newMesh(VERTEX_FORMAT, vertices, "triangles", "static")
end

function love.load()
    love.graphics.setBackgroundColor(0.53, 0.75, 0.95)
    shader = love.graphics.newShader(VERTEX_SHADER)
    scene = buildScene()
    camera = Camera.new(Vec3.new(-4, -4, 6), math.rad(45), math.rad(-25), math.rad(70), 0.05, 1000)
    love.mouse.setRelativeMode(true) -- ховаємо курсор і отримуємо лише зміщення миші
end

--- 1, -1 або 0 залежно від того, яку з двох клавіш утримують.
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

    local p = camera.position
    love.graphics.print(("position (%.1f, %.1f, %.1f)   yaw %d   pitch %d"):format(
        p.x, p.y, p.z, math.deg(camera.yaw), math.deg(camera.pitch)), 10, 10)
end

function love.mousemoved(_, _, dx, dy)
    if love.mouse.getRelativeMode() then
        -- Миша праворуч (dx > 0) повертає праворуч, тобто зменшує yaw.
        look.yaw = look.yaw - dx * MOUSE_SENSITIVITY
        look.pitch = look.pitch - dy * MOUSE_SENSITIVITY
    end
end

function love.mousepressed()
    love.mouse.setRelativeMode(true) -- клік повертає захоплення миші
end

function love.focus(focused)
    if not focused then
        love.mouse.setRelativeMode(false) -- віддаємо мишу, коли вікно втратило фокус
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
