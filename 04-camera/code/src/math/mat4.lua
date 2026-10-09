--- Матриця 4x4.
--
-- 16 чисел у порядку рядків (row-major), тому в шейдер передаємо з
-- параметром "row". Домовленості як в OpenGL: камера дивиться вздовж -Z
-- свого простору, глибина в NDC від -1 до 1.

--- @class Mat4
--- @field [integer] number Елемент (row, col) лежить за індексом (row - 1) * 4 + col.
local Mat4 = {}
Mat4.__index = Mat4

--- @param values number[] 16 чисел, по рядках.
--- @return Mat4
function Mat4.new(values)
    assert(#values == 16, "a 4x4 matrix needs 16 values")
    return setmetatable(values, Mat4)
end

--- Матриця перспективної проєкції.
--- @param fovY number Вертикальний кут огляду, радіани.
--- @param aspect number Ширина / висота вікна.
--- @param near number Відстань до ближньої площини відсікання.
--- @param far number Відстань до дальньої площини відсікання.
--- @return Mat4
function Mat4.perspective(fovY, aspect, near, far)
    local f = 1 / math.tan(fovY / 2)
    return Mat4.new({
        f / aspect, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (far + near) / (near - far), 2 * far * near / (near - far),
        0, 0, -1, 0,
    })
end

--- Матриця виду: око в точці `eye` дивиться в напрямку `direction`.
--- `direction` не може бути паралельним до `up`.
--- @param eye Vec3
--- @param direction Vec3
--- @param up Vec3
--- @return Mat4
function Mat4.lookAlong(eye, direction, up)
    local zAxis = (-direction):normalized()
    local xAxis = up:cross(zAxis):normalized()
    local yAxis = zAxis:cross(xAxis)
    return Mat4.new({
        xAxis.x, xAxis.y, xAxis.z, -xAxis:dot(eye),
        yAxis.x, yAxis.y, yAxis.z, -yAxis:dot(eye),
        zAxis.x, zAxis.y, zAxis.z, -zAxis:dot(eye),
        0, 0, 0, 1,
    })
end

--- @param row integer 1..4
--- @param col integer 1..4
--- @return number
function Mat4:get(row, col)
    return self[(row - 1) * 4 + col]
end

--- Добуток матриць `a * b` (спочатку застосовується `b`, потім `a`).
function Mat4.__mul(a, b)
    local values = {}
    for row = 1, 4 do
        for col = 1, 4 do
            local sum = 0
            for k = 1, 4 do
                sum = sum + a:get(row, k) * b:get(k, col)
            end
            values[#values + 1] = sum
        end
    end
    return Mat4.new(values)
end

return Mat4
