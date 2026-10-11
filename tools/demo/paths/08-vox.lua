-- Урок 8: світ із test.vox; облітаємо в протилежний бік, трохи вище.
return {
    duration = 32,
    camera = function(u)
        local a = -2 * math.pi * u + math.rad(225)
        local eye = { 24 + 42 * math.cos(a), 24 + 42 * math.sin(a), 34 + 3 * math.sin(2 * a) }
        return eye, { 24, 24, 6 }
    end,
}
