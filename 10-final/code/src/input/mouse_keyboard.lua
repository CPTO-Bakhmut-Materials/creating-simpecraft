--- Миша й клавіатура: захоплена миша повертає погляд, WASD/Space/Shift рухають,
-- кліки ламають і ставлять блоки, Esc закриває гру, G перемикає повний екран.

local Config = require("src.config")

--- @alias BlockAction "break"|"place"

--- Що зібрав ввід з минулого кадру.
--- @class InputFrame
--- @field forward number Від -1 до 1, як їх приймає Camera:move.
--- @field right number
--- @field up number
--- @field fast boolean Рухатися швидше.
--- @field yaw number Поворот камери з минулого кадру, радіани, як його приймає Camera:rotate.
--- @field pitch number
--- @field actions BlockAction[] Від найстаршої.

--- @class MouseKeyboardInput
--- @field yaw number Рух миші з минулого кадру, радіани.
--- @field pitch number
--- @field actions BlockAction[] Кліки з минулого кадру.
local MouseKeyboardInput = {}
MouseKeyboardInput.__index = MouseKeyboardInput

--- Захоплює мишу.
--- @return MouseKeyboardInput
function MouseKeyboardInput.new()
    love.mouse.setRelativeMode(true)
    return setmetatable({ yaw = 0, pitch = 0, actions = {} }, MouseKeyboardInput)
end

--- @param positiveKey love.KeyConstant
--- @param negativeKey love.KeyConstant
--- @return number -1, 0 або 1
local function axis(positiveKey, negativeKey)
    return (love.keyboard.isDown(positiveKey) and 1 or 0) - (love.keyboard.isDown(negativeKey) and 1 or 0)
end

--- Повертає ввід цього кадру й очищає накопичене.
--- @return InputFrame
function MouseKeyboardInput:takeFrame()
    local keys = Config.keys
    local frame = {
        forward = axis(keys.forward, keys.back), right = axis(keys.right, keys.left), up = axis(keys.up, keys.down),
        fast = love.keyboard.isDown(keys.fast),
        yaw = self.yaw, pitch = self.pitch,
        actions = self.actions,
    }
    self.yaw, self.pitch, self.actions = 0, 0, {}
    return frame
end

-- Зворотні виклики LÖVE, які реєструє src/input/init.lua.

--- @param dx number
--- @param dy number
function MouseKeyboardInput:mousemoved(dx, dy)
    if love.mouse.getRelativeMode() then
        self.yaw = self.yaw - dx * Config.mouseSensitivity
        self.pitch = self.pitch - dy * Config.mouseSensitivity
    end
end

--- @param button number
function MouseKeyboardInput:mousepressed(button)
    if not love.mouse.getRelativeMode() then
        love.mouse.setRelativeMode(true) -- клік у незахоплене вікно лише повертає мишу
    elseif button == Config.mouseButtons.breakBlock then
        self.actions[#self.actions + 1] = "break"
    elseif button == Config.mouseButtons.placeBlock then
        self.actions[#self.actions + 1] = "place"
    end
end

--- @param key love.KeyConstant
function MouseKeyboardInput:keypressed(key)
    if key == Config.keys.quit then
        love.event.quit()
    elseif key == Config.keys.fullscreen then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end

--- @param focused boolean
function MouseKeyboardInput:focus(focused)
    if not focused then
        love.mouse.setRelativeMode(false)
    end
end

return MouseKeyboardInput
