--- Гра: світ, вільна камера, рендерер і ввід гравця, а також правила, за
--- якими ламаються й ставляться блоки.

local Blocks = require("src.world.blocks")
local Camera = require("src.render.camera")
local Config = require("src.config")
local Crosshair = require("src.render.crosshair")
local Input = require("src.input")
local Raycast = require("src.world.raycast")
local Renderer = require("src.render.renderer")
local Vec3 = require("src.math.vec3")
local WorldLoader = require("src.world.load")

--- Зміна одного блока, яку обирає Game.chooseEdit.
--- @class BlockEdit
--- @field block Vec3
--- @field id BlockId Чим стає блок.

--- @class Game
--- @field world World
--- @field camera Camera
--- @field renderer Renderer
--- @field input MouseKeyboardInput
local Game = {}
Game.__index = Game

--- Ставить камеру над одним кутом світу, обличчям до його центру.
--- @param world World
--- @return Camera
local function spawnCamera(world)
    local size = world.size
    local position = Vec3.new(-0.1 * size.x, -0.1 * size.y, size.z + 6)
    return Camera.new({
        position = position,
        yaw = math.atan2(size.y / 2 - position.y, size.x / 2 - position.x),
        pitch = math.rad(-25),
        fov = Config.fov, near = Config.nearPlane, far = Config.farPlane,
    })
end

--- Завантажує світ і налаштовує ввід. Видає помилку, якщо світ не завантажився.
--- @param worldPath string Файл .vox.
--- @return Game
function Game.new(worldPath)
    local world = WorldLoader.load(worldPath)
    return setmetatable({
        world = world,
        camera = spawnCamera(world),
        renderer = Renderer.new(world, { chunkSize = Config.chunkSize, textureDir = Config.textureDir }),
        input = Input.use(),
    }, Game)
end

--- Правила: який блок змінює дія під прицілом і на що. Зламати — очистити блок
--- під прицілом; поставити — землю перед гранню під прицілом, якщо там не
--- камера. Повертає nil, якщо дія нічого не робить.
--- @param world World
--- @param camera Camera
--- @param action BlockAction
--- @return BlockEdit?
function Game.chooseEdit(world, camera, action)
    local hit = Raycast.cast(function(block) return world:isSolid(block) end,
        camera.position, camera:forward(), Config.reach)
    if not hit then
        return nil
    end
    if action == "break" then
        return { block = hit.block, id = Blocks.AIR }
    end
    if hit.normal == Vec3.ZERO then
        return nil -- камера всередині блока: немає грані, до якої прибудовувати
    end
    local target = hit.block + hit.normal
    if target == camera.position:floor() then
        return nil -- не замуровуємо камеру в блок
    end
    return { block = target, id = Blocks.DIRT }
end

--- Ламає блок або ставить блок під прицілом.
--- @param action BlockAction
function Game:interact(action)
    local edit = Game.chooseEdit(self.world, self.camera, action)
    if edit and self.world:set(edit.block, edit.id) then
        self.renderer:blockChanged(edit.block)
    end
end

--- Застосовує ввід цього кадру й перебудовує змінені чанки.
--- @param dt number Секунди від попереднього кадру.
function Game:update(dt)
    local frame = self.input:takeFrame()
    self.camera:rotate(frame.yaw, frame.pitch)
    local speed = Config.moveSpeed * (frame.fast and Config.fastMultiplier or 1)
    self.camera:move(dt, frame.forward, frame.right, frame.up, speed)
    for _, action in ipairs(frame.actions) do
        self:interact(action)
    end
    self.renderer:update()
end

function Game:draw()
    local width, height = love.graphics.getDimensions()
    self.renderer:draw(self.camera:viewProjection(width / height))
    Crosshair.draw()
end

return Game
