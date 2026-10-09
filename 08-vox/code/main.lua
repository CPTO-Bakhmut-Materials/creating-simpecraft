--- Урок 8: світ завантажується з файлу MagicaVoxel .vox.
-- Запуск: `love .` (assets/worlds/test.vox) або `love . шлях/до/світу.vox`.
-- Миша — огляд, W A S D — рух, Space / Shift — вгору / вниз, Ctrl — швидше,
-- Tab — каркасний режим, Esc — вихід.

local Camera = require("src.render.camera")
local Renderer = require("src.render.renderer")
local Vec3 = require("src.math.vec3")
local WorldLoader = require("src.world.load")

local MOVE_SPEED = 8
local FAST_MULTIPLIER = 3
local MOUSE_SENSITIVITY = 0.0025
local CHUNK_SIZE = 16
local DEFAULT_WORLD = "assets/worlds/test.vox"

local world, renderer, camera
local look = { yaw = 0, pitch = 0 }

--- @param args string[] Аргументи командного рядка після шляху до гри.
function love.load(args)
    love.graphics.setBackgroundColor(0.53, 0.75, 0.95)
    local started = love.timer.getTime()
    world = WorldLoader.load(args[1] or DEFAULT_WORLD)
    renderer = Renderer.new(world, "assets/textures", CHUNK_SIZE)
    print(("world %s loaded and built in %.2f s"):format(tostring(world.size), love.timer.getTime() - started))

    -- Камера над одним кутом світу дивиться на його центр.
    local size = world.size
    local position = Vec3.new(-0.1 * size.x, -0.1 * size.y, size.z + 6)
    local yaw = math.atan2(size.y / 2 - position.y, size.x / 2 - position.x)
    camera = Camera.new(position, yaw, math.rad(-25), math.rad(70), 0.05, 1000)
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
    renderer:draw(camera:viewProjection(width / height))
    local wireframe = love.graphics.isWireframe()
    love.graphics.setWireframe(false)
    love.graphics.print(("FPS %d   triangles %d   chunk meshes %d   Tab: wireframe"):format(
        love.timer.getFPS(), renderer.triangleCount, renderer.meshCount), 10, 10)
    love.graphics.setWireframe(wireframe)
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
    elseif key == "tab" then
        love.graphics.setWireframe(not love.graphics.isWireframe())
    end
end
