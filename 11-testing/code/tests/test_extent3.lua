local t = require("tests.lib")
local Extent3 = require("src.math.extent3")
local Vec3 = require("src.math.vec3")

t.test("extent3: index of the first cells", function()
    local size = Extent3.new(4, 3, 2)
    t.eq(size:index(Vec3.new(0, 0, 0)), 0)
    t.eq(size:index(Vec3.new(1, 0, 0)), 1, "x step is 1")
    t.eq(size:index(Vec3.new(0, 1, 0)), 4, "y step is size.x")
    t.eq(size:index(Vec3.new(0, 0, 1)), 12, "z step is size.x * size.y")
end)

t.test("extent3: every cell gets its own index, and cell() reverses index()", function()
    local size = Extent3.new(48, 48, 24)
    local seen = {}
    for z = 0, size.z - 1 do
        for y = 0, size.y - 1 do
            for x = 0, size.x - 1 do
                local cell = Vec3.new(x, y, z)
                local index = size:index(cell)
                local other = seen[index]
                t.ok(not other, ("cells %s and %s share index %d"):format(tostring(other), tostring(cell), index))
                seen[index] = cell
                t.eq(size:cell(index), cell)
            end
        end
    end
end)

t.test("extent3: contains checks every bound", function()
    local size = Extent3.new(4, 3, 2)
    t.ok(size:contains(Vec3.new(3, 2, 1)))
    t.ok(not size:contains(Vec3.new(4, 0, 0)))
    t.ok(not size:contains(Vec3.new(0, -1, 0)))
end)
