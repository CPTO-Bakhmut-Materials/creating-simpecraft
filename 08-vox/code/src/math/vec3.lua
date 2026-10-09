--- 3D-вектор для позицій і напрямків.
--
-- Вектори незмінні (immutable): оператори й методи повертають нові вектори,
-- тому один вектор можна безпечно передавати будь-куди.

--- @class Vec3
--- @field x number
--- @field y number
--- @field z number
local Vec3 = {}
Vec3.__index = Vec3

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

return Vec3
