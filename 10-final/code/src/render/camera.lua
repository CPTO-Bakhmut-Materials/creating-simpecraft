--- Вільна камера від першої особи (вісь Z — вгору). Не залежить від LÖVE.

local Mat4 = require("src.math.mat4")
local Vec3 = require("src.math.vec3")

--- @class CameraOptions
--- @field position Vec3? Типово — початок координат.
--- @field yaw number? Проти годинникової стрілки від +X.
--- @field pitch number? Додатний — дивимося вгору.
--- @field fov number Вертикальний кут огляду.
--- @field near number
--- @field far number

--- @class Camera
--- @field position Vec3 Замінюється (а не змінюється) при русі камери.
--- @field yaw number
--- @field pitch number
--- @field fov number
--- @field near number
--- @field far number
local Camera = {}
Camera.__index = Camera

local MAX_PITCH = math.rad(89) -- не даємо напрямку погляду збігтися з віссю «вгору»
local UP = Vec3.new(0, 0, 1)

--- @param options CameraOptions Кути в радіанах.
--- @return Camera
function Camera.new(options)
    local camera = setmetatable({
        position = options.position or Vec3.new(0, 0, 0),
        yaw = options.yaw or 0, pitch = 0,
        fov = options.fov, near = options.near, far = options.far,
    }, Camera)
    camera:rotate(0, options.pitch or 0)
    return camera
end

--- Одиничний вектор напрямку погляду.
--- @return Vec3
function Camera:forward()
    local cosPitch = math.cos(self.pitch)
    return Vec3.new(cosPitch * math.cos(self.yaw), cosPitch * math.sin(self.yaw), math.sin(self.pitch))
end

--- Повертає камеру; нахил обмежено трохи менше ніж прямо вгору чи вниз.
--- @param deltaYaw number
--- @param deltaPitch number
function Camera:rotate(deltaYaw, deltaPitch)
    self.yaw = (self.yaw + deltaYaw) % (2 * math.pi)
    self.pitch = math.max(-MAX_PITCH, math.min(MAX_PITCH, self.pitch + deltaPitch))
end

--- Рухає камеру. Входи від -1 до 1: `forward` — уздовж погляду,
--- `right` — убік горизонтально, `up` — уздовж світової осі Z.
--- @param dt number Секунди.
--- @param forward number
--- @param right number
--- @param up number
--- @param speed number Блоків за секунду.
function Camera:move(dt, forward, right, up, speed)
    local rightDirection = Vec3.new(math.sin(self.yaw), -math.cos(self.yaw), 0)
    local velocity = self:forward() * forward + rightDirection * right + UP * up
    local length = velocity:length()
    if length > 0 then
        self.position = self.position + velocity * (speed * dt / length)
    end
end

--- @param aspect number Ширина / висота вікна.
--- @return Mat4
function Camera:viewProjection(aspect)
    local projection = Mat4.perspective(self.fov, aspect, self.near, self.far)
    return projection * Mat4.lookAlong(self.position, self:forward(), UP)
end

return Camera
