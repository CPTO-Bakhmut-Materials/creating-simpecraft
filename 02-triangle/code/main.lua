--- Урок 2: власні вершини, сітка (Mesh) і найпростіший шейдер.
-- Tab — перемкнути каркасний режим (wireframe).

-- Формат вершини: позиція (x, y) у нормалізованих координатах пристрою
-- (NDC, від -1 до 1) та колір (r, g, b, a).
local VERTEX_FORMAT = {
    { "VertexPosition", "float", 2 },
    { "VertexColor", "byte", 4 },
}

-- Вершинний шейдер виконується на відеокарті для кожної вершини.
-- Ми повертаємо позицію як є: вона вже в NDC.
local VERTEX_SHADER = [[
vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    return vertexPosition;
}
]]

local shader, triangle, quad

function love.load()
    love.graphics.setBackgroundColor(0.53, 0.75, 0.95)
    shader = love.graphics.newShader(VERTEX_SHADER)

    -- Трикутник: три вершини, у кожної свій колір.
    triangle = love.graphics.newMesh(VERTEX_FORMAT, {
        { -0.8, -0.6, 1, 0, 0, 1 }, -- лівий нижній, червоний
        { -0.2, -0.6, 0, 1, 0, 1 }, -- правий нижній, зелений
        { -0.5, 0.4, 0, 0, 1, 1 },  -- верхній, синій
    }, "triangles", "static")

    -- Квадрат (quad) з двох трикутників. Кути: 1 лівий нижній, 2 правий
    -- нижній, 3 правий верхній, 4 лівий верхній.
    local corners = {
        { 0.2, -0.6 }, { 0.8, -0.6 }, { 0.8, 0.4 }, { 0.2, 0.4 },
    }
    local quadOrder = { 1, 2, 3, 1, 3, 4 } -- два трикутники зі спільною діагоналлю 1-3
    local vertices = {}
    for _, index in ipairs(quadOrder) do
        local corner = corners[index]
        vertices[#vertices + 1] = { corner[1], corner[2], 0.47, 0.33, 0.23, 1 }
    end
    quad = love.graphics.newMesh(VERTEX_FORMAT, vertices, "triangles", "static")
end

function love.draw()
    love.graphics.setShader(shader)
    love.graphics.setColor(1, 1, 1) -- колір вершин множиться на поточний колір
    love.graphics.draw(triangle)
    love.graphics.draw(quad)
    love.graphics.setShader()

    -- Вбудований шрифт LÖVE не має кирилиці, тому підписи в грі англійською.
    local wireframe = love.graphics.isWireframe()
    love.graphics.setWireframe(false)
    love.graphics.print("Tab: wireframe", 10, 10)
    love.graphics.setWireframe(wireframe)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "tab" then
        love.graphics.setWireframe(not love.graphics.isWireframe())
    end
end
