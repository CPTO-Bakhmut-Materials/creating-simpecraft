-- Lesson 7: the same island orbit; wireframe (Tab) is on for a third of the loop
-- to show that the hidden faces are gone.
return {
    duration = 32,
    camera = function(u)
        local a = 2 * math.pi * u + math.rad(225)
        local eye = { 24 + 44 * math.cos(a), 24 + 44 * math.sin(a), 30 + 3 * math.sin(2 * a) }
        return eye, { 24, 24, 6 }
    end,
    presses = {
        { 14, "tab" },
        { 24, "tab" },
    },
}
