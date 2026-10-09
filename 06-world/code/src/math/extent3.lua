--- Розмір тривимірної сітки клітинок, наприклад світу в блоках.
--
-- Клітинки мають цілі координати від 0 (Vec3) і вкладаються в плоский масив
-- так: найшвидше змінюється X, потім Y, потім Z (див. Extent3:index).

local Vec3 = require("src.math.vec3")

--- @class Extent3
--- @field x integer Кількість клітинок уздовж кожної осі.
--- @field y integer
--- @field z integer
local Extent3 = {}
Extent3.__index = Extent3

--- @param x integer
--- @param y integer
--- @param z integer
--- @return Extent3
function Extent3.new(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, Extent3)
end

function Extent3.__tostring(a)
    return ("%dx%dx%d"):format(a.x, a.y, a.z)
end

--- Загальна кількість клітинок.
--- @return integer
function Extent3:volume()
    return self.x * self.y * self.z
end

--- @param cell Vec3 Цілі координати.
--- @return boolean
function Extent3:contains(cell)
    return cell.x >= 0 and cell.y >= 0 and cell.z >= 0 and cell.x < self.x and cell.y < self.y and cell.z < self.z
end

--- Плоский індекс клітинки (від 0); клітинка має лежати всередині.
--- @param cell Vec3 Цілі координати.
--- @return integer
function Extent3:index(cell)
    return cell.x + self.x * (cell.y + self.y * cell.z)
end

--- Обернена до Extent3:index.
--- @param index integer
--- @return Vec3
function Extent3:cell(index)
    return Vec3.new(index % self.x, math.floor(index / self.x) % self.y, math.floor(index / (self.x * self.y)))
end

return Extent3
