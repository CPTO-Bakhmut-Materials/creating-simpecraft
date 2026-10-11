-- Lesson 4: circle the 16×16 field, gently rising and falling.
return {
    duration = 24,
    camera = function(u)
        local a = 2 * math.pi * u + math.rad(225) -- start where the lesson's camera starts: the (−x, −y) corner
        local eye = { 8 + 17 * math.cos(a), 8 + 17 * math.sin(a), 8 + 1.5 * math.sin(2 * a) }
        return eye, { 8, 8, 1.5 }
    end,
}
