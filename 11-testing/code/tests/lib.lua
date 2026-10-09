--- Найменший тестовий каркас: реєструємо тест через `test`, перевіряємо через `eq` / `ok`.

local lib = { cases = {} }

--- Реєструє тест з назвою.
function lib.test(name, fn)
    lib.cases[#lib.cases + 1] = { name = name, fn = fn }
end

local function fail(message)
    error(message, 3) -- 3: повідомлення вказує на рядок тесту, а не на цей файл
end

--- Перевіряє, що значення істинне.
function lib.ok(value, message)
    if not value then fail(message or "expected truthy value") end
end

--- Перевіряє, що `actual == expected`.
function lib.eq(actual, expected, message)
    if actual ~= expected then
        fail(("%sexpected %s, got %s"):format(message and message .. ": " or "", tostring(expected), tostring(actual)))
    end
end

--- Запускає всі тести; повертає кількість невдалих.
function lib.run()
    local failures = 0
    for _, case in ipairs(lib.cases) do
        local ok, err = pcall(case.fn)
        if not ok then
            failures = failures + 1
            print(("FAIL  %s\n      %s"):format(case.name, err))
        end
    end
    print(("%d passed, %d failed"):format(#lib.cases - failures, failures))
    return failures
end

return lib
