--- Точка входу: розбирає командний рядок і передає грі (src/game.lua) кадрові
--- зворотні виклики LÖVE. Ввід реєструє src/input/.
-- Запуск: `love . [шлях/до/світу.vox]`

local Config = require("src.config")
local Game = require("src.game")

local game --- @type Game

--- @param args string[] Аргументи командного рядка після шляху до гри.
--- @return string worldPath
local function parseArgs(args)
    local worldPath = Config.worldPath
    for _, value in ipairs(args) do
        if value:sub(1, 2) == "--" then
            error(("unknown option '%s'\nUsage: love . [path/to/world.vox]"):format(value), 0)
        end
        worldPath = value
    end
    return worldPath
end

function love.load(args)
    game = Game.new(parseArgs(args))
    love.graphics.setBackgroundColor(Config.skyColor)
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end
