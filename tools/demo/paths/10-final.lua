-- Урок 10: проліт над островом еліпсом, камера дивиться вперед і трохи вниз.
-- Еліпс (центр 26, 26; півосі 16 і 12) минає кам'яний стовп (12–13, 12–13) приблизно
-- за 4 блоки — близько, але не крізь нього.
local function point(u)
    local a = 2 * math.pi * u
    return { 26 + 16 * math.cos(a), 26 + 12 * math.sin(a), 20 + 2 * math.sin(2 * a) }
end

return {
    duration = 36,
    camera = function(u)
        -- Дивимося на точку шляху трохи попереду і нижче — погляд уперед, а не під ноги.
        local eye, ahead = point(u), point(u + 0.1)
        return eye, { ahead[1], ahead[2], ahead[3] - 5 }
    end,
}
