# Урок 10. Фінальне складання

> **Результат уроку:** завершена гра для ПК, яка за можливостями збігається з еталоном **love-mcraft**. Можна літати, ламати й ставити блоки, завантажувати будь-який світ `.vox`, перемикати повний екран (**G**). Код розкладено за відповідальністю, а всі налаштування зібрано в одному файлі.

📦 **Код уроку:** [завантажити code.zip](code.zip). Розпакуйте архів і запустіть `love code`.

![Фінальна гра](images/final.gif)

<iframe class="lesson-demo" src="demo/index.html?poster=../images/final.gif" title="Демо: проліт над островом" loading="lazy" tabindex="-1"></iframe>

## Мета уроку

* Провести **рефакторинг**: змінити будову коду, не змінюючи поведінки.
* Винести налаштування в **конфігурацію**, ввід в **окремий модуль**, правила гри в **модуль `Game`**.
* Зробити `main.lua` мінімальною точкою входу.
* Підготувати проєкт до перевірки автоматичними засобами (`luacheck`).

---

## 1. Навіщо рефакторинг, якщо все працює

Подивіться, як ріс код від уроку до уроку:

![Зростання коду](images/code_growth.g.svg)

`main.lua` уроку 9 одночасно розбирає аргументи, зберігає камеру, обробляє мишу й клавіатуру, вирішує, куди ставити блоки, і малює. Поки файл короткий, це зручно. Але кожна нова можливість (вибір блока, звук, меню) додаватиме туди ще по шматку, і невдовзі будь-яка зміна почне ламати щось сусіднє.

**Рефакторинг** — зміна будови коду **без зміни поведінки**. Після нього гра працює рівно так само, як в уроці 9, але кожен файл відповідає за одну річ.

## 2. Фінальна архітектура

![Залежності модулів](images/modules.g.svg)

| Файл | Відповідальність |
|---|---|
| `main.lua` | розбирає командний рядок; передає `love.update` / `love.draw` грі |
| `conf.lua` | налаштування вікна LÖVE до старту |
| `src/config.lua` | **усі** числа, які можна «підкрутити»: швидкості, кут огляду, клавіші |
| `src/game.lua` | гра: світ + камера + рендерер + ввід; **правила** ламання і будівництва |
| `src/input/` | миша й клавіатура → `InputFrame` раз на кадр |
| `src/render/` | камера, рендерер, мешер, приціл |
| `src/world/` | блоки, світ, `.vox`, завантаження, промінь |
| `src/math/` | `Vec3`, `Extent3`, `Mat4`; **не залежать від LÖVE** |

Стрілки на схемі йдуть **згори вниз**: модулі нижнього рівня (`math`, `world`) нічого не знають про верхні (`game`, `main`). Завдяки цьому їх можна перевіряти окремо, без запуску гри (урок 11).

## 3. Конфігурація: `src/config.lua`

```lua
return {
    worldPath = "assets/worlds/test.vox",
    textureDir = "assets/textures",
    chunkSize = 16,

    fov = math.rad(70),
    nearPlane = 0.05,
    farPlane = 1000,
    skyColor = { 0.53, 0.75, 0.95 },

    moveSpeed = 8,
    fastMultiplier = 3,
    mouseSensitivity = 0.0025,
    reach = 8,

    keys = {
        forward = "w", back = "s", left = "a", right = "d",
        up = "space", down = "lshift", fast = "lctrl",
        quit = "escape",
        fullscreen = "g",
    },
    mouseButtons = { breakBlock = 1, placeBlock = 2 },
}
```

Раніше ці числа були розкидані по `main.lua`, `camera.lua` і `renderer.lua`. Тепер, щоб змінити клавішу чи швидкість, потрібно знайти **одне** місце. У коді не залишилося «магічних чисел» без назви.

## 4. Ввід: `src/input/`

Обробка миші й клавіатури переїхала з `main.lua` в окремий клас `MouseKeyboardInput` (`src/input/mouse_keyboard.lua`). Він **накопичує** події протягом кадру, як `look` в уроці 4, і віддає їх грі одним пакетом:

```lua
local MouseKeyboardInput = {}
MouseKeyboardInput.__index = MouseKeyboardInput

function MouseKeyboardInput.new()
    love.mouse.setRelativeMode(true)
    return setmetatable({ yaw = 0, pitch = 0, actions = {} }, MouseKeyboardInput)
end

--- Повертає ввід цього кадру й очищає накопичене.
function MouseKeyboardInput:takeFrame()
    local keys = Config.keys
    local frame = {
        forward = axis(keys.forward, keys.back), right = axis(keys.right, keys.left), up = axis(keys.up, keys.down),
        fast = love.keyboard.isDown(keys.fast),
        yaw = self.yaw, pitch = self.pitch,      -- накопичений рух миші
        actions = self.actions,                  -- кліки за кадр: "break" / "place"
    }
    self.yaw, self.pitch, self.actions = 0, 0, {}
    return frame
end
```

`axis` — та сама функція з уроку 4, лише клавіші тепер беремо з `Config.keys`. Події, які раніше обробляли `love.mousemoved`, `love.mousepressed` тощо, тепер стали методами класу:

```lua
function MouseKeyboardInput:mousemoved(dx, dy)
    if love.mouse.getRelativeMode() then
        self.yaw = self.yaw - dx * Config.mouseSensitivity
        self.pitch = self.pitch - dy * Config.mouseSensitivity
    end
end

function MouseKeyboardInput:mousepressed(button)
    if not love.mouse.getRelativeMode() then
        love.mouse.setRelativeMode(true) -- клік у незахоплене вікно лише повертає мишу
    elseif button == Config.mouseButtons.breakBlock then
        self.actions[#self.actions + 1] = "break"
    elseif button == Config.mouseButtons.placeBlock then
        self.actions[#self.actions + 1] = "place"
    end
end

function MouseKeyboardInput:keypressed(key)
    if key == Config.keys.quit then
        love.event.quit()
    elseif key == Config.keys.fullscreen then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end

function MouseKeyboardInput:focus(focused)
    if not focused then
        love.mouse.setRelativeMode(false)
    end
end
```

Клік більше не ламає блок одразу, а лише **записується** в `actions`. Гра виконає його в `update`, у звичному порядку кадру.

`Game` забирає пакет раз на кадр:

```lua
function Game:update(dt)
    local frame = self.input:takeFrame()
    self.camera:rotate(frame.yaw, frame.pitch)
    local speed = Config.moveSpeed * (frame.fast and Config.fastMultiplier or 1)
    self.camera:move(dt, frame.forward, frame.right, frame.up, speed)
    for _, action in ipairs(frame.actions) do
        self:interact(action)
    end
    self.renderer:update()
end
```

`Game` не знає, **звідки** прийшов ввід. Еталонний проєкт love-mcraft саме так додає сенсорне керування для телефонів: другий клас з тим самим методом `takeFrame()`, і `Game` при цьому не змінюється.

`src/input/init.lua` робить теку модулем: `require("src.input")` завантажує саме цей файл. Він створює `MouseKeyboardInput` і реєструє зворотні виклики LÖVE:

```lua
local Input = {}

function Input.use()
    local input = MouseKeyboardInput.new()
    function love.mousemoved(_, _, dx, dy) input:mousemoved(dx, dy) end
    function love.mousepressed(_, _, button) input:mousepressed(button) end
    function love.keypressed(key) input:keypressed(key) end
    function love.focus(focused) input:focus(focused) end
    return input
end
```

Функції `love.*` можна оголосити будь-де, не лише в `main.lua`: LÖVE просто викликає ті, що існують на момент події. `_` — звичайна назва змінної для параметрів, які нам не потрібні (тут координати курсора).

> **Коментарі `--- @class`, `--- @param`.** У файлах фінального коду ви побачите рядки на кшталт `--- @param dt number`. Для Lua це звичайні коментарі. Їх читає редактор з розширенням *lua-language-server*: він підказує типи параметрів і попереджає, якщо передати число туди, де очікують `Vec3`. На роботу гри вони не впливають.

## 5. Правила гри: `Game.chooseEdit`

Функцію `interact` з уроку 9 розділено на дві частини:

* `Game.chooseEdit(world, camera, action)` **лише вирішує**, який блок і на що змінити, і повертає `{ block, id }` або `nil`. Вона нічого не змінює й не малює.
* `Game:interact(action)` **виконує** рішення: змінює світ і позначає чанки.

```lua
function Game.chooseEdit(world, camera, action)
    local hit = Raycast.cast(function(block) return world:isSolid(block) end,
        camera.position, camera:forward(), Config.reach)
    if not hit then
        return nil
    end
    if action == "break" then
        return { block = hit.block, id = Blocks.AIR }
    end
    if hit.normal == Vec3.ZERO then
        return nil -- камера всередині блока: немає грані, до якої прибудовувати
    end
    local target = hit.block + hit.normal
    if target == camera.position:floor() then
        return nil -- не замуровуємо камеру в блок
    end
    return { block = target, id = Blocks.DIRT }
end

function Game:interact(action)
    local edit = Game.chooseEdit(self.world, self.camera, action)
    if edit and self.world:set(edit.block, edit.id) then
        self.renderer:blockChanged(edit.block)
    end
end
```

Правила ті самі, що в `interact` уроку 9, лише замість зміни світу `chooseEdit` **повертає** рішення.

Таке розділення зручне для перевірки. `chooseEdit` можна викликати з вигаданим світом і камерою та порівняти результат з очікуваним, нічого не відкриваючи на екрані.

## 6. Гра і точка входу

`Game.new` збирає все разом: завантажує світ, ставить камеру, створює рендерер і ввід.

```lua
local Game = {}
Game.__index = Game

--- Ставить камеру над одним кутом світу, обличчям до його центру.
local function spawnCamera(world)
    local size = world.size
    local position = Vec3.new(-0.1 * size.x, -0.1 * size.y, size.z + 6)
    return Camera.new({
        position = position,
        yaw = math.atan2(size.y / 2 - position.y, size.x / 2 - position.x),
        pitch = math.rad(-25),
        fov = Config.fov, near = Config.nearPlane, far = Config.farPlane,
    })
end

function Game.new(worldPath)
    local world = WorldLoader.load(worldPath)
    return setmetatable({
        world = world,
        camera = spawnCamera(world),
        renderer = Renderer.new(world, { chunkSize = Config.chunkSize, textureDir = Config.textureDir }),
        input = Input.use(),
    }, Game)
end

function Game:draw()
    local width, height = love.graphics.getDimensions()
    self.renderer:draw(self.camera:viewProjection(width / height))
    Crosshair.draw()
end
```

`main.lua` тепер лише розбирає командний рядок і передає кадри грі:

```lua
local Config = require("src.config")
local Game = require("src.game")

local game

local function parseArgs(args)
    local worldPath = Config.worldPath
    for _, value in ipairs(args) do
        if value:sub(1, 2) == "--" then
            error(("unknown option '%s'\nUsage: love . [path/to/world.vox]"):format(value), 0)
        end
        worldPath = value
    end
    return worldPath
end

function love.load(args)
    game = Game.new(parseArgs(args))
    love.graphics.setBackgroundColor(Config.skyColor)
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end
```

Весь `main.lua` уміщається на одному екрані. Щоб зрозуміти гру, тепер досить прочитати `Game`.

## 7. Інші зміни

| Зміна | Навіщо |
|---|---|
| `Camera.new({ position = ..., yaw = ..., fov = ... })` | параметри з **іменами** замість шести чисел поспіль: важче переплутати порядок |
| `Renderer.new(world, { chunkSize = ..., textureDir = ... })` | те саме |
| перевірка `getTextureTypes()["array"]` | на старій відеокарті — зрозуміле повідомлення замість дивної помилки шейдера |
| `t.window.msaa = 4` | згладжування «драбинок» на краях блоків |
| `t.modules.audio = false` тощо | не завантажувати модулі, які гра не використовує |
| клавіша **G** | повний екран |
| невідомий параметр `--щось` | зрозуміле повідомлення про використання |

**Параметри з іменами.** Замість шести чисел поспіль `Camera.new` приймає одну таблицю. Відсутні поля отримують значення за замовчуванням через `or`:

```lua
function Camera.new(options)
    local camera = setmetatable({
        position = options.position or Vec3.new(0, 0, 0),
        yaw = options.yaw or 0, pitch = 0,
        fov = options.fov, near = options.near, far = options.far,
    }, Camera)
    camera:rotate(0, options.pitch or 0)
    return camera
end
```

`a or b` повертає `a`, якщо воно не `nil` (і не `false`), інакше `b`. `Renderer.new(world, options)` змінився так само: `options.chunkSize`, `options.textureDir`.

**Перевірка відеокарти** — перший рядок після завантаження текстур у `Renderer.new`:

```lua
assert(love.graphics.getTextureTypes()["array"], "array textures are not supported by this graphics card")
```

**`conf.lua`** фінальної версії:

```lua
function love.conf(t)
    t.identity = "lesson-mcraft"
    t.version = "11.5"

    t.window.title = "love-mcraft"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = 1
    t.window.depth = 24 -- буфер глибини
    t.window.msaa = 4   -- згладжування країв (multisample anti-aliasing)

    -- Модулі, які гра не використовує, не завантажуємо.
    t.modules.audio = false
    t.modules.sound = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end
```

### Згладжування (MSAA)

![Порівняння msaa = 0 і msaa = 4](images/msaa_compare.png)

**MSAA** (*multisample anti-aliasing*) перевіряє кілька точок усередині кожного пікселя на краю трикутника і змішує результат. «Драбинки» на краях зникають, а текстури всередині граней лишаються чіткими.

## 8. Запуск і перевірка якості

```sh
cd 10-final/code
love .                      # світ за замовчуванням
love . /шлях/до/світу.vox   # інший світ
luacheck .                  # статичний аналіз коду (якщо встановлено)
```

**`luacheck`** — це *лінтер*, програма, яка читає код **без запуску** і шукає типові помилки: опечатки в назвах змінних, невикористані змінні, випадкові глобальні змінні. Налаштування лежать у `.luacheckrc`. Для фінального коду luacheck не знаходить жодного зауваження.

Повний код: [`code.zip`](code.zip).

## 9. ⚠️ Типова помилка: крапка замість двокрапки

Під час рефакторингу виклики методів змінюються масово, і легко написати:

```lua
function love.update(dt)
    game.update(dt)   -- НЕПРАВИЛЬНО: має бути game:update(dt)
end
```

![Екран помилки LÖVE](images/error_self.png)

`game:update(dt)` — скорочення для `game.update(game, dt)`. З крапкою `self` отримує число `dt`, і перше ж звернення `self.input` падає з помилкою **«attempt to index local 'self' (a number value)»**.

Читати таке повідомлення слід так:

1. **Перший рядок** (`src/game.lua:92`) показує, де сталася помилка.
2. **Traceback** читаємо знизу вгору, це ланцюжок викликів. `main.lua:29` — місце, звідки викликали метод, і саме там помилка.
3. Фраза «`self` (a number value)» майже завжди означає, що замість `:` стоїть `.`.

> **Порада:** не бійтеся екрана помилки. Він показує **файл і рядок**. Найгірші помилки ті, що не дають жодного повідомлення: перевернуті UV, зсунута палітра, дірки між чанками. Саме від них захищають автоматичні тести.

## 10. Порівняння з еталоном

| Можливість | love-mcraft (еталон) | Курс |
|---|---|---|
| Світ з `.vox`, редагування в Goxel | ✅ | ✅ |
| Камера, рух, ламання й будівництво | ✅ | ✅ |
| Текстури, приховані грані, чанки | ✅ | ✅ |
| Повний екран, Esc, захоплення миші | ✅ | ✅ |
| Сенсорне керування (телефони, планшети) | ✅ | ❌ курс лише для ПК |
| Запуск у браузері (love.js, WebAssembly) | ✅ | ❌ курс лише для ПК |
| Автоматичні тести | ✅ 15 наборів тестів | вступ, див. урок 11 |
| Перевірка типів (lua-language-server), CI на GitHub | ✅ | ❌ лише згадано |

## Підсумок

* Рефакторинг змінює будову коду, не змінюючи поведінки.
* Налаштування — в `config.lua`; ввід — в `src/input/`; правила гри — в `Game`.
* Модулі нижнього рівня не залежать від верхніх, тому їх можна перевіряти окремо.
* Повідомлення про помилку вказує файл і рядок; traceback читаємо знизу вгору.

## Запитання для самоперевірки

1. Змініть керування на стрілки замість WASD. Скільки файлів довелося змінити?
2. Чому `Game.chooseEdit` викликається через крапку, а `Game:interact` через двокрапку?
3. Додайте до `config.lua` параметр `placeBlock` (який блок ставити) і використайте його в `Game.chooseEdit`.

**Далі:** [Урок 11. Тестування: вступ](../11-testing/README.md)
