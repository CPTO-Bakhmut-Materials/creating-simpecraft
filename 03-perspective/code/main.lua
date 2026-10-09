--- Урок 3: перспективна проєкція. Камера літає по колу навколо кольорового куба.

local Mat4 = require("src.math.mat4")
local Vec3 = require("src.math.vec3")

local FOV = math.rad(70)
local NEAR, FAR = 0.05, 100
local UP = Vec3.new(0, 0, 1) -- вісь Z дивиться вгору, як у форматі .vox

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

-- Шість граней одиничного куба [0, 1]³. Кути кожної грані перелічено
-- проти годинникової стрілки, якщо дивитися на грань ззовні.
local FACES = {
    { color = { 0.85, 0.25, 0.25 }, corners = { { 1, 0, 0 }, { 1, 1, 0 }, { 1, 1, 1 }, { 1, 0, 1 } } }, -- +X
    { color = { 0.45, 0.10, 0.10 }, corners = { { 0, 1, 0 }, { 0, 0, 0 }, { 0, 0, 1 }, { 0, 1, 1 } } }, -- -X
    { color = { 0.25, 0.75, 0.30 }, corners = { { 1, 1, 0 }, { 0, 1, 0 }, { 0, 1, 1 }, { 1, 1, 1 } } }, -- +Y
    { color = { 0.10, 0.40, 0.15 }, corners = { { 0, 0, 0 }, { 1, 0, 0 }, { 1, 0, 1 }, { 0, 0, 1 } } }, -- -Y
    { color = { 0.30, 0.45, 0.95 }, corners = { { 0, 0, 1 }, { 1, 0, 1 }, { 1, 1, 1 }, { 0, 1, 1 } } }, -- +Z
    { color = { 0.10, 0.15, 0.45 }, corners = { { 0, 1, 0 }, { 1, 1, 0 }, { 1, 0, 0 }, { 0, 0, 0 } } }, -- -Z
}
local QUAD_ORDER = { 1, 2, 3, 1, 3, 4 }

local shader, cube
local time = 0

--- Будує сітку куба з центром у початку координат.
local function buildCube()
    local vertices = {}
    for _, face in ipairs(FACES) do
        for _, cornerIndex in ipairs(QUAD_ORDER) do
            local corner, color = face.corners[cornerIndex], face.color
            vertices[#vertices + 1] = {
                corner[1] - 0.5, corner[2] - 0.5, corner[3] - 0.5,
                color[1], color[2], color[3], 1,
            }
        end
    end
    return love.graphics.newMesh(VERTEX_FORMAT, vertices, "triangles", "static")
end

function love.load()
    love.graphics.setBackgroundColor(0.53, 0.75, 0.95)
    shader = love.graphics.newShader(VERTEX_SHADER)
    cube = buildCube()
end

function love.update(dt)
    time = time + dt
end

function love.draw()
    -- Камера рухається по колу радіусом 3 на висоті 1.5 і дивиться в центр куба.
    local angle = time * 0.6
    local eye = Vec3.new(3 * math.cos(angle), 3 * math.sin(angle), 1.5)
    local view = Mat4.lookAlong(eye, -eye, UP)

    local width, height = love.graphics.getDimensions()
    local projection = Mat4.perspective(FOV, width / height, NEAR, FAR)

    love.graphics.push("all")
    love.graphics.setShader(shader)
    shader:send("viewProjection", "row", projection * view)
    love.graphics.setDepthMode("lequal", true) -- ближчі пікселі перекривають дальші
    love.graphics.draw(cube)
    love.graphics.pop()

    love.graphics.print(("eye = (%.1f, %.1f, %.1f)"):format(eye.x, eye.y, eye.z), 10, 10)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
