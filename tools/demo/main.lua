--- Демо-режим уроку для книги (збирає tools/build-demos.sh, у браузері — love.js).
--
-- Код уроку не змінюється: його main.lua перейменовано на lesson_main.lua, а цей
-- файл запускає його і робить показ неінтерактивним:
--   * справжній ввід вимкнено — клавіатура «нічого не натиснуто», події миші й
--     клавіш до уроку не доходять, курсор не захоплюється;
--   * сценарій demo_path.lua (свій для кожного уроку) замкнено в цикл: він рухає
--     камеру, «натискає» клавіші або вмикає каркасний режим у заданий момент.
--
-- Формат demo_path.lua:
--   duration = секунди одного циклу;
--   camera   = function(u) → eye {x, y, z}, target {x, y, z}   (u від 0 до 1);
--   keys     = { {from, to, {"d", ...}}, ... } — клавіші, «утримувані» на відрізку часу;
--   presses  = { {t, "tab"}, ... }          — разові натискання в момент t.

local Path = require("demo_path")

-- Камеру урок створює сам; перехоплюємо її, щойно викликано Camera.new.
local camera
do
    local ok, Camera = pcall(require, "src.render.camera")
    if ok then
        local new = Camera.new
        Camera.new = function(...)
            camera = new(...)
            return camera
        end
    end
end

-- Клавіші «утримує» лише сценарій.
local held = {}
love.keyboard.isDown = function(...)
    for i = 1, select("#", ...) do
        if held[select(i, ...)] then return true end
    end
    return false
end
love.mouse.setRelativeMode = function() end
love.mouse.getRelativeMode = function() return false end
love.mouse.setGrabbed = function() end

love.filesystem.load("lesson_main.lua")()

local lesson = { load = love.load, update = love.update, keypressed = love.keypressed }
local INPUT_CALLBACKS = { "mousemoved", "mousepressed", "mousereleased", "wheelmoved",
    "keypressed", "keyreleased", "textinput", "focus" }

local function silenceInput()
    for _, name in ipairs(INPUT_CALLBACKS) do
        love[name] = nil
    end
end

function love.load()
    -- Аргументів командного рядка в браузері немає: урок бере свій світ за замовчуванням.
    if lesson.load then lesson.load({}, {}) end
    -- Урок 10 реєструє обробники вводу всередині love.load, тож беремо їх звідти.
    lesson.keypressed = love.keypressed or lesson.keypressed
    silenceInput()
end

local time = 0

local function keysAt(t)
    local set = {}
    for _, span in ipairs(Path.keys or {}) do
        if t >= span[1] and t < span[2] then
            for _, key in ipairs(span[3]) do set[key] = true end
        end
    end
    return set
end

-- Найближча межа відрізка «клавіші» після t (щоб не розмазати її по кадру).
local function nextBoundary(t)
    local best = Path.duration
    for _, span in ipairs(Path.keys or {}) do
        for k = 1, 2 do
            if span[k] > t + 1e-9 and span[k] < best then best = span[k] end
        end
    end
    return best
end

local function firePresses(from, to)
    if not lesson.keypressed then return end
    for _, press in ipairs(Path.presses or {}) do
        if press[1] > from and press[1] <= to then lesson.keypressed(press[2]) end
    end
end

local function placeCamera()
    if not (camera and Path.camera) then return end
    local Vec3 = require("src.math.vec3")
    local eye, target = Path.camera(time / Path.duration)
    local dx, dy, dz = target[1] - eye[1], target[2] - eye[2], target[3] - eye[3]
    camera.position = Vec3.new(eye[1], eye[2], eye[3])
    camera.yaw = math.atan2(dy, dx)
    camera.pitch = math.atan2(dz, math.sqrt(dx * dx + dy * dy))
end

function love.update(dt)
    dt = math.min(dt, 0.1) -- після паузи вкладки не перестрибуємо півсцени
    -- Ділимо кадр на межах відрізків клавіш: так рух за сценарієм точний і цикл не «пливе».
    while dt > 0 do
        local step = math.min(dt, nextBoundary(time) - time)
        held = keysAt(time)
        if lesson.update then lesson.update(step) end
        firePresses(time, time + step)
        time = time + step
        dt = dt - step
        if time >= Path.duration - 1e-9 then
            time = 0
            firePresses(-1, 0)
        end
    end
    placeCamera()
end
