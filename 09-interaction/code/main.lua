--- Урок 9: приціл, промінь і зміна світу: лівий клік ламає блок, правий ставить землю.
-- Запуск: `love .` (assets/worlds/test.vox) або `love . шлях/до/світу.vox`.
-- Миша — огляд, W A S D — рух, Space / Shift — вгору / вниз, Ctrl — швидше, Esc — вихід.

local Blocks = require("src.world.blocks")
local Camera = require("src.render.camera")
local Crosshair = require("src.render.crosshair")
local Raycast = require("src.world.raycast")
local Renderer = require("src.render.renderer")
local Vec3 = require("src.math.vec3")
local WorldLoader = require("src.world.load")

local MOVE_SPEED = 8
local FAST_MULTIPLIER = 3
local MOUSE_SENSITIVITY = 0.0025
local CHUNK_SIZE = 16
local REACH = 8 -- на скільки блоків дотягується гравець
local DEFAULT_WORLD = "assets/worlds/test.vox"

local world, renderer, camera
local look = { yaw = 0, pitch = 0 }

--- @param args string[] Аргументи командного рядка після шляху до гри.
function love.load(args)
    love.graphics.setBackgroundColor(0.53, 0.75, 0.95)
    world = WorldLoader.load(args[1] or DEFAULT_WORLD)
    renderer = Renderer.new(world, "assets/textures", CHUNK_SIZE)

    local size = world.size
    local position = Vec3.new(-0.1 * size.x, -0.1 * size.y, size.z + 6)
    local yaw = math.atan2(size.y / 2 - position.y, size.x / 2 - position.x)
    camera = Camera.new(position, yaw, math.rad(-25), math.rad(70), 0.05, 1000)
    love.mouse.setRelativeMode(true)
end

--- Перший твердий блок під прицілом (або nil).
--- @return RaycastHit?
local function target()
    return Raycast.cast(function(block) return world:isSolid(block) end, camera.position, camera:forward(), REACH)
end

--- Ламає блок під прицілом ("break") або ставить землю до грані під прицілом ("place").
--- @param action "break"|"place"
local function interact(action)
    local hit = target()
    if not hit then
        return
    end
    local block, id = hit.block, Blocks.AIR
    if action == "place" then
        if hit.normal == Vec3.ZERO then
            return -- камера всередині блока: немає грані, до якої прибудовувати
        end
        block, id = hit.block + hit.normal, Blocks.DIRT
        if block == camera.position:floor() then
            return -- не замуровуємо камеру в блок
        end
    end
    if world:set(block, id) then
        renderer:blockChanged(block)
    end
end

local function axis(positiveKey, negativeKey)
    return (love.keyboard.isDown(positiveKey) and 1 or 0) - (love.keyboard.isDown(negativeKey) and 1 or 0)
end

function love.update(dt)
    camera:rotate(look.yaw, look.pitch)
    look.yaw, look.pitch = 0, 0
    local speed = MOVE_SPEED * (love.keyboard.isDown("lctrl") and FAST_MULTIPLIER or 1)
    camera:move(dt, axis("w", "s"), axis("d", "a"), axis("space", "lshift"), speed)
    renderer:update()
end

function love.draw()
    local width, height = love.graphics.getDimensions()
    renderer:draw(camera:viewProjection(width / height))
    Crosshair.draw()

    local hit = target()
    love.graphics.print(("target %s"):format(hit and tostring(hit.block) or "-"), 10, 10)
end

function love.mousemoved(_, _, dx, dy)
    if love.mouse.getRelativeMode() then
        look.yaw = look.yaw - dx * MOUSE_SENSITIVITY
        look.pitch = look.pitch - dy * MOUSE_SENSITIVITY
    end
end

function love.mousepressed(_, _, button)
    if not love.mouse.getRelativeMode() then
        love.mouse.setRelativeMode(true) -- клік у незахоплене вікно лише повертає мишу
    elseif button == 1 then
        interact("break")
    elseif button == 2 then
        interact("place")
    end
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
