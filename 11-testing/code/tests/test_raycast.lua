local t = require("tests.lib")
local Raycast = require("src.world.raycast")
local Vec3 = require("src.math.vec3")

-- Вигаданий «світ»: твердий лише один блок. Raycast приймає функцію isSolid,
-- тому для перевірки не потрібні ні World, ні файл .vox, ні LÖVE.
local function onlyBlock(target)
    return function(block) return block == target end
end

t.test("raycast: hits the block ahead through the face facing the ray", function()
    local hit = Raycast.cast(onlyBlock(Vec3.new(5, 0, 0)), Vec3.new(0.5, 0.5, 0.5), Vec3.new(1, 0, 0), 10)
    t.ok(hit, "expected a hit")
    t.eq(hit.block, Vec3.new(5, 0, 0))
    t.eq(hit.normal, Vec3.new(-1, 0, 0), "entered through the -X face")
end)

t.test("raycast: misses a block beyond reach", function()
    t.eq(Raycast.cast(onlyBlock(Vec3.new(20, 0, 0)), Vec3.new(0.5, 0.5, 0.5), Vec3.new(1, 0, 0), 8), nil)
end)

t.test("raycast: looking down hits the top face", function()
    local hit = Raycast.cast(onlyBlock(Vec3.new(2, 3, 0)), Vec3.new(2.5, 3.5, 6), Vec3.new(0, 0, -1), 8)
    t.ok(hit, "expected a hit")
    t.eq(hit.normal, Vec3.new(0, 0, 1))
end)
