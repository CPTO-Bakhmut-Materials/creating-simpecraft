-- Lesson 10: an elliptical flyover of the island, the camera looking ahead and slightly down.
-- The ellipse (centre 26, 26; semi-axes 16 and 12) passes the stone pillar (12–13, 12–13)
-- at about 4 blocks: close, but not through it.
local function point(u)
    local a = 2 * math.pi * u
    return { 26 + 16 * math.cos(a), 26 + 12 * math.sin(a), 20 + 2 * math.sin(2 * a) }
end

return {
    duration = 36,
    camera = function(u)
        -- Look at a path point a little ahead and below: forward, not at our feet.
        local eye, ahead = point(u), point(u + 0.1)
        return eye, { ahead[1], ahead[2], ahead[3] - 5 }
    end,
}
