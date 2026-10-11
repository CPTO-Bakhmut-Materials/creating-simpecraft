--- Lesson demo mode for the book (packed by tools/build-demos.sh, run by love.js).
--
-- The lesson code is unchanged: its main.lua is renamed to lesson_main.lua, and
-- this file runs it and makes the show non-interactive:
--   * real input is off: the keyboard reports "nothing pressed", mouse and key
--     events never reach the lesson, and the cursor is never captured;
--   * the script demo_path.lua (one per lesson) runs in a loop: it moves the
--     camera, "holds" keys or toggles wireframe at given moments.
--
-- demo_path.lua format:
--   duration = seconds per loop;
--   camera   = function(u) → eye {x, y, z}, target {x, y, z}   (u from 0 to 1);
--   keys     = { {from, to, {"d", ...}}, ... } — keys "held" during a time span;
--   presses  = { {t, "tab"}, ... }          — single key presses at time t.

local Path = require("demo_path")

-- The lesson creates its own camera; capture it as soon as Camera.new is called.
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

-- Only the script "holds" keys.
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
    -- There are no command-line arguments in the browser: the lesson loads its default world.
    if lesson.load then lesson.load({}, {}) end
    -- Lesson 10 registers its input callbacks inside love.load, so take them from there.
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

-- The next key-span boundary after t (so a boundary is never smeared across a frame).
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
    dt = math.min(dt, 0.1) -- after a paused tab, don't jump half the scene ahead
    -- Split the frame at key-span boundaries: scripted movement stays exact and the loop doesn't drift.
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
