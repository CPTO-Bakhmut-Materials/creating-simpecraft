--- Запускає тести. З кореня проєкту: `luajit tests/run.lua` (LÖVE не потрібен).

local lib = require("tests.lib")

require("tests.test_extent3")
require("tests.test_raycast")

os.exit(lib.run() == 0 and 0 or 1)
