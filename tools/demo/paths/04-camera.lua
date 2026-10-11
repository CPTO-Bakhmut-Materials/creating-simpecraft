-- Урок 4: облітаємо поле 16×16 по колу, плавно піднімаючись і опускаючись.
return {
    duration = 24,
    camera = function(u)
        local a = 2 * math.pi * u + math.rad(225) -- старт там, де камера уроку: з кута (−x, −y)
        local eye = { 8 + 17 * math.cos(a), 8 + 17 * math.sin(a), 8 + 1.5 * math.sin(2 * a) }
        return eye, { 8, 8, 1.5 }
    end,
}
