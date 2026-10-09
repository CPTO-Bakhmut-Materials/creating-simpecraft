function love.conf(t)
    t.identity = "lesson-mcraft"
    t.version = "11.5"

    t.window.title = "love-mcraft"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = 1
    t.window.depth = 24 -- буфер глибини
    t.window.msaa = 4   -- згладжування країв (multisample anti-aliasing)

    -- Модулі, які гра не використовує, не завантажуємо.
    t.modules.audio = false
    t.modules.sound = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end
