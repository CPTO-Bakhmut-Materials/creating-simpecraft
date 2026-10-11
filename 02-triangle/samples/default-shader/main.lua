--- Приклад до уроку 2: що буде, якщо не замінити стандартний шейдер LÖVE.
-- Чотири панелі 640×360:
--   ліворуч угорі   — наш шейдер: координати вершин уже в NDC (-1..1), усе на місці;
--   праворуч угорі  — ті самі сітки зі стандартним шейдером: він вважає координати
--                     пікселями, тож фігури стискаються в куток (0, 0) і зникають;
--   ліворуч унизу   — цей куток, збільшений у 100 разів: жоден центр пікселя не
--                     потрапляє у фігури, тому не зафарбовано жодного пікселя;
--   праворуч унизу  — стандартний шейдер з love.graphics.translate/scale: фігури
--                     видно, але перевернутими, бо в пікселях вісь Y дивиться вниз.
-- Запуск: love . (з цієї теки).

local VERTEX_FORMAT = {
    { "VertexPosition", "float", 2 },
    { "VertexColor", "byte", 4 },
}

local VERTEX_SHADER = [[
vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    return vertexPosition;
}
]]

local W, H = 640, 360
local SKY = { 0.53, 0.75, 0.95 }
local ZOOM = 100

local shader, triangle, quad, font
local panels = {}

local function buildMeshes()
    triangle = love.graphics.newMesh(VERTEX_FORMAT, {
        { -0.8, -0.6, 1, 0, 0, 1 },
        { -0.2, -0.6, 0, 1, 0, 1 },
        { -0.5, 0.4, 0, 0, 1, 1 },
    }, "triangles", "static")
    local corners = { { 0.2, -0.6 }, { 0.8, -0.6 }, { 0.8, 0.4 }, { 0.2, 0.4 } }
    local vertices = {}
    for _, index in ipairs({ 1, 2, 3, 1, 3, 4 }) do
        local c = corners[index]
        vertices[#vertices + 1] = { c[1], c[2], 0.47, 0.33, 0.23, 1 }
    end
    quad = love.graphics.newMesh(VERTEX_FORMAT, vertices, "triangles", "static")
end

local function drawMeshes()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(triangle)
    love.graphics.draw(quad)
end

-- Draws into a 640×360 canvas; returns the canvas.
local function panel(draw)
    local canvas = love.graphics.newCanvas(W, H)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(SKY)
    draw()
    love.graphics.setCanvas()
    return canvas
end

function love.load()
    shader = love.graphics.newShader(VERTEX_SHADER)
    font = love.graphics.newFont(20)
    buildMeshes()

    panels.custom = panel(function()
        love.graphics.setShader(shader)
        drawMeshes()
        love.graphics.setShader()
    end)
    panels.default = panel(drawMeshes)
    panels.scaled = panel(function()
        love.graphics.push()
        love.graphics.translate(W / 2, H / 2)
        love.graphics.scale(150)
        drawMeshes()
        love.graphics.pop()
    end)
end

-- The top-left corner of the "default" panel, magnified: pixel grid, pixel centres,
-- and the meshes at the same scale (the default shader honours love.graphics.scale).
local function drawZoom(x0, y0)
    love.graphics.setScissor(x0, y0, W, H)
    love.graphics.setColor(0.25, 0.27, 0.3)
    love.graphics.rectangle("fill", x0, y0, W, H)
    local ox, oy = x0 + 1.4 * ZOOM, y0 + 1.1 * ZOOM -- where pixel (0, 0) starts
    love.graphics.setColor(SKY)
    love.graphics.rectangle("fill", ox, oy, W, H)

    love.graphics.push()
    love.graphics.translate(ox, oy)
    love.graphics.scale(ZOOM)
    drawMeshes()
    love.graphics.pop()

    love.graphics.setLineWidth(1)
    for i = -2, 5 do
        love.graphics.setColor(1, 1, 1, i >= 0 and 0.8 or 0.25)
        love.graphics.line(ox + i * ZOOM, y0, ox + i * ZOOM, y0 + H)
        love.graphics.line(x0, oy + i * ZOOM, x0 + W, oy + i * ZOOM)
    end
    love.graphics.setColor(0.1, 0.1, 0.1)
    for i = 0, 4 do
        for j = 0, 2 do
            love.graphics.circle("fill", ox + (i + 0.5) * ZOOM, oy + (j + 0.5) * ZOOM, 4)
        end
    end
    love.graphics.setScissor()
end

local function label(text, x, y)
    love.graphics.setFont(font)
    local w = font:getWidth(text) + 16
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x + 8, y + 8, w, 32, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x + 16, y + 13)
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    -- Our shader ignores transformProjection, which is what flips canvas rendering
    -- right side up in LÖVE, so this canvas is drawn mirrored back.
    love.graphics.draw(panels.custom, 0, H, 0, 1, -1)
    love.graphics.draw(panels.default, W, 0)
    drawZoom(0, H)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(panels.scaled, W, H)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(4)
    love.graphics.line(W, 0, W, 2 * H)
    love.graphics.line(0, H, 2 * W, H)

    label("our shader: NDC", 0, 0)
    label("default shader: nothing?", W, 0)
    label("its corner (0, 0), x100", 0, H)
    label("default shader + translate/scale", W, H)
end
