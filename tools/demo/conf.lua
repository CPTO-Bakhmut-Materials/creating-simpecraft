--- Налаштування демо (збирає tools/build-demos.sh): conf.lua уроку без змін,
-- перейменований на lesson_conf.lua, плюс одна поправка для браузера.

love.filesystem.load("lesson_conf.lua")()
local lessonConf = love.conf

function love.conf(t)
    lessonConf(t)
    -- Рушій love.js — LÖVE 11.4, а уроки написано для 11.5. Розбіжність версій LÖVE
    -- показує вікном-попередженням, а в браузері це alert(), що зупиняє сторінку.
    -- Код уроків від цієї різниці не залежить, тож оголошуємо версію самого рушія.
    t.version = love._version
    -- Фіксований кадр 1280×720, як в уроці: сторінка лише масштабує його під розмір рамки.
    -- Інакше вікно підлаштувалося б під рамку, і квадрат уроку 1 виїхав би за край.
    t.window.resizable = false
    -- Однопотокова збірка love.js падає («RuntimeError: null function»), якщо модулі
    -- звуку вимкнено, як в уроці 10. Демо звуку не відтворює, тож просто вмикаємо їх.
    t.modules.audio = true
    t.modules.sound = true
end
