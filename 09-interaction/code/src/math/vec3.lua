--- 3D-вектор для позицій, напрямків, нормалей і координат блоків та чанків.
--
-- Вектори незмінні (immutable): оператори й методи повертають нові вектори,
-- тому один вектор можна безпечно передавати будь-куди.

--- @class Vec3
--- @field x number
--- @field y number
--- @field z number
local Vec3 = {}
Vec3.__index = Vec3

--- Три осі, для коду, що обробляє їх однаково (`v[axis]`).
Vec3.AXES = { "x", "y", "z" }

--- @param x number
--- @param y number
--- @param z number
--- @return Vec3
function Vec3.new(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, Vec3)
end

function Vec3.__add(a, b)
    return Vec3.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vec3.__sub(a, b)
    return Vec3.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

--- Множення на число: `v * s` (число пишемо другим).
function Vec3.__mul(a, b)
    return Vec3.new(a.x * b, a.y * b, a.z * b)
end

function Vec3.__div(a, b)
    return Vec3.new(a.x / b, a.y / b, a.z / b)
end

function Vec3.__unm(a)
    return Vec3.new(-a.x, -a.y, -a.z)
end

--- Порівняння за координатами (звичайне `==` для таблиць порівнювало б, чи це той самий об'єкт).
function Vec3.__eq(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

function Vec3.__tostring(a)
    return ("(%g, %g, %g)"):format(a.x, a.y, a.z)
end

--- Скалярний добуток.
--- @param other Vec3
--- @return number
function Vec3:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

--- Векторний добуток `self × other` (права система координат).
--- @param other Vec3
--- @return Vec3
function Vec3:cross(other)
    return Vec3.new(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x)
end

--- @return number
function Vec3:length()
    return math.sqrt(self:dot(self))
end

--- Одиничний вектор того ж напрямку; вектор не може бути нульовим.
--- @return Vec3
function Vec3:normalized()
    local length = self:length()
    return Vec3.new(self.x / length, self.y / length, self.z / length)
end

--- Округлює кожну координату вниз, наприклад щоб знайти блок, що містить точку.
--- @return Vec3
function Vec3:floor()
    return Vec3.new(math.floor(self.x), math.floor(self.y), math.floor(self.z))
end

--- Будує вектор з функції від назви осі, для формул «по кожній осі».
--- @param component fun(axis: "x"|"y"|"z"): number
--- @return Vec3
function Vec3.fromAxes(component)
    return Vec3.new(component("x"), component("y"), component("z"))
end

--- Одиничний вектор уздовж осі, наприклад `unit("y")` — це (0, 1, 0).
--- @param axis "x"|"y"|"z"
--- @return Vec3
function Vec3.unit(axis)
    return Vec3.fromAxes(function(other) return other == axis and 1 or 0 end)
end

--- Вісь з найменшою координатою; при рівності — пізніша вісь (z, потім y, потім x).
--- @return "x"|"y"|"z"
function Vec3:smallestAxis()
    local best = "x"
    for _, axis in ipairs(Vec3.AXES) do
        if self[axis] <= self[best] then
            best = axis
        end
    end
    return best
end

--- (0, 0, 0). Спільний для всіх, як і будь-який вектор, тому його не змінюють.
Vec3.ZERO = Vec3.new(0, 0, 0)

return Vec3
