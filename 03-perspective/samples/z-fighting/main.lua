--- Приклад до уроку 3: z-fighting — «мерехтіння» далеких граней, коли near замале.
-- Ліворуч near = 0.05, як у нашому коді; праворуч near = 0.0001, решта однакова.
-- Кольорові смуги лежать над сірою землею лише на 2 см, а кольорові квадрати —
-- на 2 см перед стіною за 60 м. Буферу глибини бракує точності розрізнити такі
-- близькі поверхні вдалині, і на правій половині вони «прориваються» одна крізь одну.
-- Запуск: love . (з цієї теки).

local FOV = math.rad(70)
local FAR = 400
local NEARS = { 0.05, 0.0001 }
local GAP = 0.02 -- 2 см між поверхнями

local VERTEX_FORMAT = {
    { "VertexPosition", "float", 3 },
    { "VertexColor", "byte", 4 },
}

local VERTEX_SHADER = [[
uniform mat4 viewProjection;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    return viewProjection * vertexPosition;
}
]]

local shader, scene, views
local time = 0

-- Матриці — як Mat4.perspective і Mat4.lookAlong уроку 3 (рядки підряд).
local function perspective(aspect, near)
    local f = 1 / math.tan(FOV / 2)
    return {
        f / aspect, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (FAR + near) / (near - FAR), 2 * FAR * near / (near - FAR),
        0, 0, -1, 0,
    }
end

local function normalize(x, y, z)
    local l = math.sqrt(x * x + y * y + z * z)
    return x / l, y / l, z / l
end

local function lookAlong(ex, ey, ez, dx, dy, dz)
    local zx, zy, zz = normalize(-dx, -dy, -dz)               -- камера дивиться в −Z
    local xx, xy, xz = normalize(-zy, zx, 0)                  -- up × zAxis, up = (0, 0, 1)
    local yx, yy, yz = zy * xz - zz * xy, zz * xx - zx * xz, zx * xy - zy * xx
    return {
        xx, xy, xz, -(xx * ex + xy * ey + xz * ez),
        yx, yy, yz, -(yx * ex + yy * ey + yz * ez),
        zx, zy, zz, -(zx * ex + zy * ey + zz * ez),
        0, 0, 0, 1,
    }
end

local function multiply(a, b)
    local m = {}
    for row = 0, 3 do
        for col = 1, 4 do
            local sum = 0
            for k = 1, 4 do
                sum = sum + a[row * 4 + k] * b[(k - 1) * 4 + col]
            end
            m[row * 4 + col] = sum
        end
    end
    return m
end

--- Прямокутник із двох трикутників у площині, заданій чотирма кутами.
local function quad(vertices, corners, color)
    for _, i in ipairs({ 1, 2, 3, 1, 3, 4 }) do
        local c = corners[i]
        vertices[#vertices + 1] = { c[1], c[2], c[3], color[1], color[2], color[3], 1 }
    end
end

local function buildScene()
    local v = {}
    -- Земля: сірі плитки 4×4 від камери вдалину.
    for i = -15, 14 do
        for j = -1, 39 do
            local g = (i + j) % 2 == 0 and 0.55 or 0.62
            local x, y = i * 4, j * 4
            quad(v, { { x, y, 0 }, { x + 4, y, 0 }, { x + 4, y + 4, 0 }, { x, y + 4, 0 } }, { g, g, g })
        end
    end
    -- Смуги «розмітки» на висоті GAP над землею.
    for _, s in ipairs({ { -6, { 0.95, 0.75, 0.1 } }, { 0, { 0.95, 0.95, 0.95 } }, { 6, { 0.2, 0.45, 0.95 } } }) do
        local x = s[1]
        quad(v, { { x - 0.5, 2, GAP }, { x + 0.5, 2, GAP }, { x + 0.5, 158, GAP }, { x - 0.5, 158, GAP } }, s[2])
    end
    -- Стіна за 60 м і кольорові квадрати на GAP перед нею.
    local wy = 60
    quad(v, { { -40, wy, 0 }, { -40, wy, 30 }, { 40, wy, 30 }, { 40, wy, 0 } }, { 0.85, 0.85, 0.82 })
    local colors = { { 0.85, 0.25, 0.25 }, { 0.25, 0.7, 0.3 }, { 0.3, 0.45, 0.95 } }
    for k = 0, 5 do
        local x = -33 + k * 11
        quad(v, { { x, wy - GAP, 6 }, { x, wy - GAP, 16 }, { x + 9, wy - GAP, 16 }, { x + 9, wy - GAP, 6 } },
            colors[k % 3 + 1])
    end
    return love.graphics.newMesh(VERTEX_FORMAT, v, "triangles", "static")
end

function love.load()
    shader = love.graphics.newShader(VERTEX_SHADER)
    scene = buildScene()
    local w, h = love.graphics.getDimensions()
    views = {}
    for k, near in ipairs(NEARS) do
        views[k] = { near = near, canvas = love.graphics.newCanvas(w / 2, h) }
    end
end

function love.update(dt)
    time = time + dt
end

function love.draw()
    -- Камера на висоті людини повільно повертається ліворуч-праворуч (цикл 12 с).
    local a = 0.18 * math.sin(2 * math.pi * time / 12)
    local view = lookAlong(0, -2, 1.7, math.sin(a), math.cos(a), -0.06)
    local w, h = love.graphics.getDimensions()

    for _, v in ipairs(views) do
        love.graphics.push("all")
        love.graphics.setCanvas({ v.canvas, depth = true })
        love.graphics.clear(0.53, 0.75, 0.95, 1, false, 1)
        love.graphics.setShader(shader)
        local m = multiply(perspective((w / 2) / h, v.near), view)
        -- У полотно (Canvas) LÖVE малює перевернутим по вертикалі; власна проєкція LÖVE
        -- це враховує, а наша матриця — ні, тож перевертаємо y самі (другий рядок).
        for col = 5, 8 do m[col] = -m[col] end
        shader:send("viewProjection", "row", m)
        love.graphics.setDepthMode("lequal", true)
        love.graphics.draw(scene)
        love.graphics.pop()
    end

    love.graphics.setColor(1, 1, 1)
    for k, v in ipairs(views) do
        local x = (k - 1) * w / 2
        love.graphics.draw(v.canvas, x, 0)
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", x + 10, 10, 150, 26, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(("near = %g"):format(v.near), x + 20, 16)
    end
    love.graphics.setColor(0.12, 0.16, 0.2)
    love.graphics.rectangle("fill", w / 2 - 2, 0, 4, h)
    love.graphics.setColor(1, 1, 1)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
