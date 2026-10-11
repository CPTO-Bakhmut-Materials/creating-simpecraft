-- Lesson 9: a closer orbit, with the crosshair visible over the blocks.
return {
    duration = 28,
    camera = function(u)
        local a = 2 * math.pi * u + math.rad(225)
        local eye = { 24 + 26 * math.cos(a), 24 + 26 * math.sin(a), 22 + 2 * math.sin(2 * a) }
        return eye, { 24, 24, 8 }
    end,
}
