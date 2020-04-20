-- Sony compatibility module

--btw, the reason why these functions are defined as weirdly as they are is to not break
--compatibility with the Lua Player Plus API, which this initially was built against.

function drawImage(x, y, i, c)
    Graphics.drawImage(x, y, i, c)
end

function buttonDown(m)
    local pad = Controls.read()
    return Controls.check(pad, m)
end

function playSound(s)
    Sound.play(s, NO_LOOP)
end

function newColour(r, g, b, a)
    if not a then a = 255 end
    return Color.new(r, g, b, a)
end

function getR(c)
    return Color.getR(c)
end

function getG(c)
    return Color.getG(c)
end

function getB(c)
    return Color.getB(c)
end

function fontPrint(fnt, x, y, str, color)
    Font.print(fnt, x, y, str, color)
end

function fillRect(x1, x2, y1, y2, color)
    Graphics.fillRect(x1, x2, y1, y2, color)
end

function loadImage(path)
    return Graphics.loadImage('app0:/data/'..path)
end

function loadFontAtSize(path, size)
    local font = Font.load('app0:/data/'..path)
    Font.setPixelSizes(font, size)
    return font
end

function loadSound(path)
    return Sound.open('app0:/data/'..path)
end

compat = {}
function compat.beforeDraw()
    Graphics.initBlend()
    Screen.clear()
end

function compat.afterDraw()
    Graphics.termBlend()
    Screen.flip()

    Screen.waitVblankStart()
end

function compat.init()
    System.setCpuSpeed(444)
    System.setGpuSpeed(111)
    System.setBusSpeed(222)
    Sound.init()
end

function getSeed()
    local h,m,s = System.getTime() 
	local dv,d,m,y = System.getDate()
    local seed = s + 60*s + h*3600 + d*24*3600
    return seed
end

cTimer = {}
-- for love2d, i'll have to majorly fudge the LPP timer class
function cTimer.new()
    local nobj = Timer.new()
    return nobj
end

function cTimer.pause(ct)
    Timer.pause(ct)
end

function cTimer.resume(ct)
    Timer.resume(ct)
end

function cTimer.isPlaying(ct)
    return Timer.isPlaying(ct)
end

function cTimer.getTime(ct)
    return Timer.getTime(ct)
end

function cTimer.reset(ct)
    return Timer.reset(ct)
end

function cTimer.setTime(ct, ms)
    Timer.setTime(ct, ms)
end

function cTimer.update(ct, dt)
    -- nothing. I don't need to in the SCE impl
end

STD_BTN_UP = SCE_CTRL_UP
STD_BTN_DOWN = SCE_CTRL_DOWN
STD_BTN_LEFT = SCE_CTRL_LEFT
STD_BTN_RIGHT = SCE_CTRL_RIGHT
STD_BTN_A = SCE_CTRL_CIRCLE
STD_BTN_B = SCE_CTRL_CROSS
STD_BTN_C = SCE_CTRL_SQUARE
STD_BTN_START = SCE_CTRL_START
STD_BTN_D = SCE_CTRL_LTRIGGER
_STD_BTN_D2 = SCE_CTRL_RTRIGGER

function gameLoop(u, d)
    local t = 1/60--Timer.getTime(fpsTimer)/1000 --get the game to run at the *CORRECT* framerate
    u(t)
    d(t)
    return true
end

function print(h)
    -- literally do nothing, as print is a debug function that i'll only use on the PC version
end

function cdofile(f)
    dofile(f)
end