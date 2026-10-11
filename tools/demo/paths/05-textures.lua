-- Урок 5: те саме поле, ближче й нижче, щоб було видно текстури.
return {
    duration = 24,
    camera = function(u)
        local a = 2 * math.pi * u + math.rad(225)
        local eye = { 8 + 14 * math.cos(a), 8 + 14 * math.sin(a), 9 + 1.5 * math.sin(2 * a) }
        return eye, { 8, 8, 3 }
    end,
}
