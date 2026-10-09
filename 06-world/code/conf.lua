function love.conf(t)
    t.identity = "lesson-mcraft"
    t.version = "11.5"

    t.window.title = "Урок 6: світ із блоків"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = 1
    t.window.depth = 24 -- буфер глибини: без нього 3D-сцена малюється неправильно
end
