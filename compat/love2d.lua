-- Love2D compatibility module

--btw, the reason why these functions are defined as weirdly as they are is to not break
--compatibility with the Lua Player Plus API, which this initially was built against.

function drawImage(x, y, i, c)
    love.graphics.setColor(c)
    love.graphics.draw(i, x, y)
    love.graphics.setColor(1, 1, 1, 1)
end

function buttonDown(m)
    return love.keyboard.isDown(m)
end

function playSound(s)
    s:clone():play()
end

function newColour(r, g, b, a)
    if not a then a = 255 end
    return {r/255, g/255, b/255, a/255}
end

function getR(c)
    return c[1] * 255
end

function getG(c)
    return c[2] * 255
end

function getB(c)
    return c[3] * 255
end

function fontPrint(fnt, x, y, str, color)
    love.graphics.setFont(fnt)
    love.graphics.setColor(unpack(color))
    love.graphics.print(str, x, y)
end

function fillRect(x1, x2, y1, y2, color)
    love.graphics.setColor(unpack(color))
    love.graphics.rectangle('fill', x1, y1, x2-x1, y2-y1)
    love.graphics.setColor(1, 1, 1)
end

function loadImage(path)
    return love.graphics.newImage('data/'..path)
end

function loadFontAtSize(path, size)
    local font = love.graphics.newFont('data/'..path, size)
    return font
end

function loadSound(path)
    return love.audio.newSource('data/'..path, 'static')
end

compat = {}
function compat.beforeDraw()
    -- nothing
end

function compat.afterDraw()
    -- nothing part 2
end

function compat.init()
    -- nothing part 3
end

function getSeed()
    return os.time()
end

cTimer = {}
-- yep
function cTimer.new()
    local nobj = {
        time = 0,
        paused = false
    }
    return nobj
end

function cTimer.pause(ct)
    ct.paused = true
end

function cTimer.resume(ct)
    ct.paused = false
end

function cTimer.isPlaying(ct)
    return not ct.paused
end

function cTimer.getTime(ct)
    return ct.time * 1000
end

function cTimer.reset(ct)
    ct.time = 0
end

function cTimer.setTime(ct, ms)
    ct.time = ms
end

function cTimer.update(ct, dt)
   ct.time = ct.time + dt --mm, fudge
end

STD_BTN_UP = "up"
STD_BTN_DOWN = "down"
STD_BTN_LEFT = "left"
STD_BTN_RIGHT = "right"
STD_BTN_A = "a"
STD_BTN_B = "s"
STD_BTN_C = "d"
STD_BTN_START = "return"
STD_BTN_D = "space"
_STD_BTN_D2 = nil

function gameLoop(u, d)
    love.update = u
    love.draw = d
end

function cdofile(f)
    assert(love.filesystem.load(f))()
end

function dbgprint(str)
    love.graphics.print(str, 0, 0)
end