--- Ввід гравця: створює MouseKeyboardInput і реєструє для нього зворотні
-- виклики LÖVE. Гра отримує результат раз на кадр через takeFrame().
--
-- Файл init.lua робить теку модулем: `require("src.input")` завантажує саме його.

local MouseKeyboardInput = require("src.input.mouse_keyboard")

local Input = {}

--- Налаштовує ввід і реєструє зворотні виклики LÖVE.
--- @return MouseKeyboardInput input Викликайте takeFrame() раз на кадр.
function Input.use()
    local input = MouseKeyboardInput.new()
    function love.mousemoved(_, _, dx, dy) input:mousemoved(dx, dy) end
    function love.mousepressed(_, _, button) input:mousepressed(button) end
    function love.keypressed(key) input:keypressed(key) end
    function love.focus(focused) input:focus(focused) end
    return input
end

return Input
