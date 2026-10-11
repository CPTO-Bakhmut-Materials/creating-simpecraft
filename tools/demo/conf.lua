--- Demo settings (packed by tools/build-demos.sh): the lesson's conf.lua unchanged,
-- renamed to lesson_conf.lua, plus a few browser-specific fixes.

love.filesystem.load("lesson_conf.lua")()
local lessonConf = love.conf

function love.conf(t)
    lessonConf(t)
    -- The love.js runtime is LÖVE 11.4, while the lessons target 11.5. LÖVE reports a
    -- version mismatch with a warning dialog, which in a browser is a blocking alert().
    -- The lesson code doesn't depend on the difference, so declare the runtime's own version.
    t.version = love._version
    -- Fixed 1280×720 frame as in the lesson; the page only scales it to fit the iframe.
    -- Otherwise the window would resize to the frame and lesson 1's square would leave the screen.
    t.window.resizable = false
    -- The single-threaded love.js build crashes ("RuntimeError: null function") when the
    -- audio modules are disabled, as lesson 10 does. Demos play no sound, so just enable them.
    t.modules.audio = true
    t.modules.sound = true
end
