--- Налаштування гри. Кути в радіанах, відстані в блоках.

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
