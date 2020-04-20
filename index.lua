if not PLATFORM then
    PLATFORM = 'sony'
end

if not cdofile then
    cdofile = dofile
end

function pathTransform(p)
    local s = 'app0:/'
    if PLATFORM == 'pc' then
        s = ''
    end
    return s .. p
end

function adofile(s)
    cdofile(pathTransform(s))
end

COMPAT = 'sony'
if PLATFORM == 'pc' then
    COMPAT = 'love2d'
end

adofile('compat/'..COMPAT..'.lua')

adofile('script/util.lua')
adofile('script/colours.lua')
adofile('script/pieces_ars.lua')

compat.init()

WORLD_RULE = false

REVERSE_ROTATIONS = false

audio = {
    irs = loadSound('irs.wav'),
    fall = loadSound('fall.wav'),
    clear = loadSound('clear.wav'),
    lock = loadSound('lock.wav'),
    place = loadSound('place.wav'),
    ready = loadSound('ready.wav'),
    go = loadSound('go.wav'),
    gradeup = loadSound('gradeup.wav'),
    gameclear = loadSound('gameclear.wav')
}

pieceaudio = {'I', 'J', 'L', 'S', 'T', 'O', 'Z'}
for _, i in ipairs(pieceaudio) do
    pieceaudio[i] = loadSound('piece/'..i..'.wav')
end

FONT_SIZE = 36

font = loadFontAtSize('standard.ttf', FONT_SIZE)

DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

background = loadImage('back.png')
block = loadImage('block.png')
smallblock = loadImage('smallblock.png')

FIELD_HEIGHT = 20
FIELD_WIDTH = 10
HIDDEN_HEIGHT = 4
BLOCK_SIZE = 24
SMALLBLOCK_SIZE = 16

state = 'rotselect'

game = {}

buttons = {
    up = false,
    down = false,
    left = false,
    right = false,
    rotateleft = false,
    rotateright = false,
    rotateleft2 = false,
    start = false,
    _hold = false,
    _hold2 = false,
    hold = false
}
lastbuttons = deepcopy(buttons)
justpressed = deepcopy(buttons)
mapping = {
    up = STD_BTN_UP,
    down = STD_BTN_DOWN,
    left = STD_BTN_LEFT,
    right = STD_BTN_RIGHT,
    rotateleft = STD_BTN_A,
    rotateright = STD_BTN_B,
    rotateleft2 = STD_BTN_C,
    start = STD_BTN_START,
    _hold = STD_BTN_D,
    _hold2 = _STD_BTN_D2
}

FIELD = {}
for y=1,FIELD_HEIGHT+HIDDEN_HEIGHT do
    FIELD[y] = {}
    for x=1,FIELD_WIDTH do
        FIELD[y][x] = 0
    end
end

function pstring(h, y, c)
    if not c then c = colours.WHITE end
    local rs = (DISPLAY_WIDTH/2)-((#h*FONT_SIZE)/4)
    fontPrint(font, rs, y, h, c)
end

duringCountdown = false
countdowntimer = 0
countdownstage = 0
lastcstage = 0

function game:initialise(style)
    duringCountdown = false
    countdowntimer = 0
    countdownstage = 0
    lastcstage = 0

    FIELD = {}
    for y=1,FIELD_HEIGHT+HIDDEN_HEIGHT do
        FIELD[y] = {}
        for x=1,FIELD_WIDTH do
            FIELD[y][x] = 0
        end
    end

    self.timer = cTimer.new()
    cTimer.pause(self.timer)
    self.x = 3
    self.y = HIDDEN_HEIGHT-1
    self.rotationstate = 1
    self.running = false

    local seed = getSeed()
	math.randomseed(seed)

    self.delays = {
        gravity = 1/64,
        das = 12 * (1/60),
        arr = 1 * (1/60),
        lock = 30 * (1/60),
        clear = 12 * (1/60),
        are = 10 * (1/60),
        lare = 15 * (1/60)
    }
    
    self.counters = {
        gravity = 0,
        das = 0,
        arr = 0,
        lock = 0,
        clear = 0,
        are = 0,
        sdGravity = 0
    }

    -- rng shit below
    -- abandon all hope, all ye who enter
    self.history = {'Z','Z','S','S'}
    self.firstPiece = true
    self.randomiserPieces = {}
    for i, _ in pairs(pieces) do
        table.insert(self.randomiserPieces, i)
    end
    -- is it over? thank god it's over
    
    -- sike
    self.nextQueue = {}
    for i=1,128 do
        table.insert(self.nextQueue, self:generatePiece())
    end
    -- ok we're actually done this time

    self.piece = self.nextQueue[1]
    if self.piece == 'O' then
        self.x = self.x + 1
    end
    self.pieceActive = true

    self.clearing = false
    self.lines = 0

    self.shiftDownRows = {}

    self._placeAudio = false

    self.drawGhost = true

    self.level = 0
    self.currsection = 1
    self.endlevel = 999

    self.gamestyle = style

    self.dead = false

    self.holdPiece = nil
    self.holdAvailable = true

    self.softDropFrames = 0

    self.blockSonic = false

    self.levelAddTables = {
        [0] = 0,
        1,
        2,
        3,
        4
    }

    if mode and mode.init then
        mode:init(style)
    end
end

function game:generatePiece()
    while self.firstPiece do
        local h = self.randomiserPieces[math.random(1, #self.randomiserPieces)]
        if h ~= 'S' and h ~= 'Z' and h ~= 'O' then
            self.firstPiece = false
            return h
        end
    end
    local h = self.randomiserPieces[math.random(1, #self.randomiserPieces)]
    for _=0, 6 do
        if tableindex(self.history, h) == -1 then
            -- piece not in history
            table.insert(self.history, 1, h) -- push
            table.remove(self.history) -- pop
            return h
        end
        h = self.randomiserPieces[math.random(1, #self.randomiserPieces)]
    end
    return h
end

function game:start()
    self.running = true
    cTimer.resume(self.timer)
    table.remove(self.nextQueue, 1)
    local ps = pieceaudio[self.nextQueue[1]]
    if ps then
        playSound(ps) 
    end
end

function game:update(dt)
    cTimer.update(self.timer, dt)

    if justpressed.hold then
        self:hold()
    end
    if justpressed.left then
        self:movePiece(-1, 0)
    end
    if justpressed.right then
        self:movePiece(1, 0)
    end
    if justpressed.rotateleft or justpressed.rotateleft2 then
        self:rotate(-1)
    elseif justpressed.rotateright then
        self:rotate(1)
    end
    if justpressed.up then
        self:sonicDrop() 
    end

    if justpressed.start then
        self:gameOver()
    end

    self:shiftDownTimer(dt)
    self:doDAS(dt)
    self:doARR(dt)
    self:doGravity(dt)
    self:doLock(dt)
    self:doARE(dt)
end

function game:doDAS(dt)
    if buttons.left then
        if self.counters.das > 0 then self.counters.das = 0 end
        self.counters.das = self.counters.das - dt
    elseif buttons.right then
        if self.counters.das < 0 then self.counters.das = 0 end
        self.counters.das = self.counters.das + dt
    else
        self.counters.das = 0
    end
end

function game:doARR(dt)
    if not self.pieceActive then return end
    if self.counters.das < self.delays.das * -1 then
        self.counters.arr = self.counters.arr + dt
        while self.counters.arr >= self.delays.arr do
            self:movePiece(-1, 0)
            self.counters.arr = self.counters.arr - self.delays.arr
            local j = 1
            if self:isColliding(nil, self.x-j) then break end
        end
    end
    if self.counters.das > self.delays.das then
        self.counters.arr = self.counters.arr + dt
        while self.counters.arr >= self.delays.arr do
            self:movePiece(1, 0)
            self.counters.arr = self.counters.arr - self.delays.arr
            local j = 1
            if self:isColliding(nil, self.x+j) then break end
        end
    end
end

function game:doGravity(dt)
    if not self.pieceActive then return end
    local baseG = 1/60
    if buttons.down and self.delays.gravity < 1 then
        self:doSoftDrop(dt)
        return
    else
        self.counters.sdGravity = 0
    end
    self.counters.gravity = self.counters.gravity + dt
    local f = self.delays.gravity
    while self.counters.gravity >= (baseG/f) do
        self.counters.gravity = self.counters.gravity - (baseG/f)
        if self:isColliding(nil, nil, self.y+1) then break end
        self.counters.lock = 0
        self:movePiece(0, 1)
    end
end

function game:doSoftDrop(dt)
    self.counters.sdGravity = self.counters.sdGravity + dt
    while self.counters.sdGravity >= 1/60 do
        self.counters.sdGravity = self.counters.sdGravity - 1/60
        if self:isColliding(nil, nil, self.y+1) then break end
        self.softDropFrames = self.softDropFrames + 1
        self.counters.lock = 0
        self:movePiece(0, 1)
    end
end

function game:movePiece(ex, ey)
    local tx, ty = self.x+ex, self.y+ey
    if not self:isColliding(nil, tx, ty) then
        self.x, self.y = tx, ty
    end
end

function game:isColliding(piece, px, py)
    if not piece then piece = pieces[self.piece][self.rotationstate] end
    local ax, ay = self.x, self.y
    if px then
        ax = px
    end
    if py then
        ay = py
    end
    local res = false
    local h, w = #piece, #piece[1]
    for y = 1, h, 1 do
        for x = 1, w, 1 do
            local b = piece[y][x]
            local t = (FIELD[y+ay] or {nil, nil, nil, nil})[x+ax]
            if t == nil then
                t = true
            end
            if t ~= 0 and (b == 1) then
                res = true
            end
        end
    end
    return res
end

function game:doLock(dt)
    if not self:isColliding(nil, nil, self.y+1) or not self.pieceActive then
        self._placeAudio = false
        return
    end
    if not self._placeAudio then
        playSound(audio.place)
        self._placeAudio = true
    end
    self.counters.lock = self.counters.lock + dt
    if self.counters.lock >= self.delays.lock or (buttons.down and not WORLD_RULE) then
        self.counters.lock = 0
        self:lock()
    end
end

function game:isOnBoard(x, y)
    local e = FIELD[y]
    if not e then return false end
    return e[x] ~= nil
end

function game:placePieceOnField()
    for y=1,#pieces[self.piece][self.rotationstate] do
        for x=1,#pieces[self.piece][self.rotationstate][y] do
            local isOnBoard = self:isOnBoard(self.x+x, self.y+y)
            local isPresent = pieces[self.piece][self.rotationstate][y][x] == 1
            if isPresent and isOnBoard then
                FIELD[self.y+y][self.x+x] = self.piece
            end
        end
    end
end

function game:findLowestY()
    for y=self.y,FIELD_HEIGHT+HIDDEN_HEIGHT do
        if self:isColliding(nil, nil, y+1) then
            return y
        end
    end
    return 1
end

function game:sonicDrop()
    if not self.pieceActive or self.blockSonic then return end
    local ny = self:findLowestY()

    self.softDropFrames = self.softDropFrames + (ny - self.y)

    if WORLD_RULE then
        self.counters.lock = self.delays.lock
    else
        if ny ~= self.y then
            self.counters.lock = 0
        end
    end

    self.y = ny
end

function game:lock()
    self.pieceActive = false
    self:placePieceOnField()
    local lines = self:clearLines()
    self.lines = self.lines + lines
    if mode and mode.clear then
        mode:clear(lines)
    end

    if lines >= 1 then
        playSound(audio.clear)
        self:incrementLevel(self.levelAddTables[lines], lines)
        self.clearing = true
        self.counters.clear = self.delays.clear
        self:shiftDownTimer(0) -- 0-shift special case
    else
        playSound(audio.lock)
        self.counters.are = self.delays.are
    end
end

function game:hasPerfectCleared()
    for y=1,FIELD_HEIGHT+HIDDEN_HEIGHT,1 do
        for x=1,FIELD_WIDTH do
            local ft = FIELD[y][x]
            if ft ~= 0 then return false end
        end
    end
    return true
end

function game:shiftDownTimer(dt)
    if not self.clearing then return end
    self.counters.clear = self.counters.clear - dt
    if self.counters.clear <= 0 then
        self.clearing = false
        playSound(audio.fall)
        self:shiftDown()
        self.counters.are = self.delays.lare
    end
end

function game:clearLines()
    local count = 0
    local board = deepcopy(FIELD)
    local empty = {}
    for y=1,FIELD_HEIGHT+HIDDEN_HEIGHT,1 do
        local perform = true
        for x=1,FIELD_WIDTH do
            if board[y][x] == 0 then
                perform = false
            end
            table.insert(empty, 0)
        end
        if perform then
            count = count + 1
            for x=1,FIELD_WIDTH do
                board[y][x] = 0
            end
            table.insert(self.shiftDownRows, y)
        end
    end
    FIELD = board
    return count
end

function game:shiftDown()
    local count = 0
    local board = deepcopy(FIELD)
    local empty = {}
    for x=1,FIELD_WIDTH do
        table.insert(empty, 0)
    end
    for _, y in ipairs(self.shiftDownRows) do
        count = count + 1
        for shiftdown=y,1,-1 do
            if self:isOnBoard(1, shiftdown-1) then
                board[shiftdown] = deepcopy(board[shiftdown-1]) or empty
            end
        end
    end
    FIELD = board -- jasklf
    self.shiftDownRows = {}
    return count
end

function game:doARE(dt)
    if self.pieceActive or self.clearing then return end
    self.counters.are = self.counters.are - dt
    if self.counters.are <= 0 then
        self:nextPiece()
    end
end

function game:nextPiece(held)
    self.x = 3
    self.y = HIDDEN_HEIGHT-1
    self.piece = self.nextQueue[1]
    table.remove(self.nextQueue, 1)
    table.insert(self.nextQueue, self:generatePiece())
    if self.piece == 'O' then
        self.x = self.x + 1
    end
    self.pieceActive = true
    self.rotationstate = 1
    self.counters.lock = 0
    self.counters.are = 0
    self.counters.arr = 0
    self.counters.gravity = 0
    self.softDropFrames = 0
    self.holdAvailable = true

    if not held then
        self:incrementLevel(1, 0)
    end

    if buttons.hold and not held then
        self:hold()
    end

    if buttons.rotateleft or buttons.rotateleft2 then
        playSound(audio.irs)
        game:rotate(-1)
    elseif buttons.rotateright then
        playSound(audio.irs)
        game:rotate(1)
    end

    local ps = pieceaudio[self.nextQueue[1]]
    if ps then
        playSound(ps) 
    end

    if self:isColliding(nil, 3, HIDDEN_HEIGHT-1) then
        self:gameOver()
    end

    self:doGravity(0)
end

function game:gameOver()
    self.dead = true
    self.running = false
    cTimer.pause(self.timer)
end

function game:hold()
    if not self.holdAvailable or self.gamestyle ~= 'extended' or not self.pieceActive then return end
    if self.holdPiece == nil then
        self.holdPiece = self.piece
        self.pieceActive = false
        self:nextPiece(true)
    else
        local h = self.holdPiece
        self.holdPiece = self.piece
        self.piece = h
        self.x, self.y = 3, HIDDEN_HEIGHT-1
        self.rotationstate = 1
        if h == 'O' then self.x = self.x + 1 end
        self.counters.lock = 0
        self.counters.gravity = 0
    end
    self.holdAvailable = false
end

function game:rotate(dir)
    if REVERSE_ROTATIONS then
        dir = dir * -1
    end

    local states = #pieces[self.piece]
    local provstate = self.rotationstate + dir
    if provstate < 1 then
        provstate = states
    end
    provstate = math.fmod(provstate-1, states)+1
    local st = pieces[self.piece][provstate]
    if self:isColliding(st) then
        -- piece in wall
        local fail, mx, my = game_wallkick(self, st, self.rotationstate, provstate)
        if fail then
            return
        end
        self.x = self.x + mx
        self.y = self.y + my
    end
    self.rotationstate = provstate
    self.lastAction = 'rotate'
    --self.counters.lock = 0
end

function game:hasBlock(x, y)
    local e = FIELD[y]
    if not e then return true end
    return e[x] ~= 0
end

function game:incrementLevel(lvls, lines)
    if self.level == self.endlevel - 1 and self.lines == 0 then return end
    if self.level % 100 ~= 99 or lines ~= 0 then
        self.level = self.level + lvls
    end

    if mode and mode.setDelays then
        mode:setDelays()
    end
end

menuselect = 1
game_style = 'classic'

function update(dt)
    for i, _ in pairs(buttons) do
        if mapping[i] ~= nil then
            buttons[i] = buttonDown(mapping[i])
        end
    end
    buttons.hold = (buttons._hold or buttons._hold2) -- hack to map multiple shit to one thing
    for i, _ in pairs(buttons) do
        if buttons[i] and not lastbuttons[i] then
            justpressed[i] = true
        else
            justpressed[i] = false
        end
    end
    lastbuttons = deepcopy(buttons)

    if state == 'game' then
        if duringCountdown then
            countdowntimer = countdowntimer + dt
            countdownstage = math.floor(countdowntimer)+1
            if countdownstage==1 and lastcstage==0 then
                playSound(audio.ready)
            end
            if countdownstage==2 and lastcstage==1 then
                playSound(audio.go)
            end
            if countdownstage==3 and lastcstage==2 then
                duringCountdown = false
                countdownstage = 0
                lastcstage = 0
                game:start()
            end
            lastcstage = countdownstage
        end

        if game.dead and justpressed.rotateright then
            menuselect = 1
            state = 'rotselect'
        end
    elseif state == 'menu' then
        local MODE_NUMBER = 1
        local modes = {'script/mode_master.lua'}
        if justpressed.down then
            menuselect = menuselect + 1
            if menuselect > MODE_NUMBER then
                menuselect = 1
            end
        end
        if justpressed.up then
            menuselect = menuselect - 1
            if menuselect < 1 then
                menuselect = MODE_NUMBER
            end
        end
        if justpressed.rotateright then
            adofile(modes[menuselect])
            game:initialise(game_style)
            duringCountdown = true
            state = 'game'
        end
        if justpressed.rotateleft then
            menuselect = 1
            state = 'styleselect'
        end
    elseif state == 'rotselect' then
        if justpressed.down then
            menuselect = menuselect + 1
            if menuselect > 2 then
                menuselect = 1
            end
        end
        if justpressed.up then
            menuselect = menuselect - 1
            if menuselect < 1 then
                menuselect = 2
            end
        end
        if justpressed.rotateright then
            if menuselect == 1 then
                -- classic
                adofile('script/pieces_ars.lua')
            end
            if menuselect == 2 then
                -- world
                adofile('script/pieces_srs.lua')
            end
            menuselect = 1
            state = 'styleselect'
        end
    elseif state == 'styleselect' then
        if justpressed.down then
            menuselect = menuselect + 1
            if menuselect > 2 then
                menuselect = 1
            end
        end
        if justpressed.up then
            menuselect = menuselect - 1
            if menuselect < 1 then
                menuselect = 2
            end
        end
        if justpressed.rotateright then
            if menuselect == 1 then
                -- classic
                game_style = 'classic'
            end
            if menuselect == 2 then
                -- extended
                game_style = 'extended'
            end
            menuselect = 1
            state = 'menu'
        end
        if justpressed.rotateleft then
            menuselect = 1
            state = 'rotselect'
        end
    end
    if game.running then
        game:update(dt)
    end
end

function draw(dt)
    compat.beforeDraw()
    --yes 

    drawImage(0, 0, background, newColour(100, 100, 100))

    -- actual drawing here

    local rs = (DISPLAY_WIDTH/2)-((BLOCK_SIZE*FIELD_WIDTH)/2)
    local re = (DISPLAY_WIDTH/2)+((BLOCK_SIZE*FIELD_WIDTH)/2)
    local rs2 = (DISPLAY_HEIGHT/2)-((BLOCK_SIZE*FIELD_HEIGHT)/2)
    local re2 = (DISPLAY_HEIGHT/2)+((BLOCK_SIZE*FIELD_HEIGHT)/2)
    fillRect(rs, re, rs2, re2, newColour(0, 0, 0, 128))

    if state == 'game' then
        if duringCountdown then
            local strings = {'READY', 'GO!'}
            if countdownstage>0 and countdownstage<=#strings then
                pstring(strings[countdownstage], 250)
            end
        end

        local tt = cTimer.getTime(game.timer)
        local min = math.floor((tt / 1000) / 60)
        local sec = math.floor((tt / 1000) % 60)
        local ms = padstart(string.sub(tostring(math.floor(tt % 1000)), 1, 2), 2, '0')
        local timer = string.format('%02d:%02d:%s', min, sec, ms)
        fontPrint(font, re+20, re2-60, timer, ternary(cTimer.isPlaying(game.timer), colours.WHITE, newColour(100, 100, 100)))

        fontPrint(font, re+20, re2-150, padstart(tostring(game.level), 3, '0'), colours.WHITE)
        local cs = (math.floor(game.level / 100)+1) * 100
        if cs > game.endlevel then
            cs = game.endlevel
        end
        fontPrint(font, re+20, re2-120, padstart(tostring(cs), 3, '0'), colours.WHITE)

        local renderfield = deepcopy(FIELD)
        if game.pieceActive and game.running then
            local s = pieces[game.piece][game.rotationstate]
            for y=1,#s do
                for x=1,#s[y] do
                    if s[y][x] == 1 then
                        local c = piececolours[game.piece]
                        if not c then
                            c = colours.WHITE
                        end
                        -- build lock delay colour
                        local f = (game.delays.lock - game.counters.lock) / game.delays.lock
                        f = (f * 0.5) + 0.5
                        local nc = newColour(getR(c) * f, getG(c) * f, getB(c) * f)

                        drawImage(rs+(BLOCK_SIZE*((game.x+x)-1)), rs2+(BLOCK_SIZE*((game.y+y)-(HIDDEN_HEIGHT+1))), block, nc)
                    end
                end
            end

            if game.drawGhost and not game.dead then
                local ly = game:findLowestY()
                for y=1,#s do
                    for x=1,#s[y] do
                        if s[y][x] == 1 then
                            local c = piececolours[game.piece]
                            if not c then
                                c = colours.WHITE
                            end
                            -- build ghost colour
                            local nc = newColour(getR(c), getG(c), getB(c), 100)
    
                            drawImage(rs+(BLOCK_SIZE*((game.x+x)-1)), rs2+(BLOCK_SIZE*((ly+y)-(HIDDEN_HEIGHT+1))), block, nc)
                        end
                    end
                end
            end
        end
        for y=1,FIELD_HEIGHT+HIDDEN_HEIGHT do
            for x=1,FIELD_WIDTH do
                local f = renderfield[y][x]
                if f ~= 0 then
                    local c = piececolours[f]
                    if not c then
                        c = colours.WHITE
                    end
                    if game.dead then
                        c = newColour(100, 100, 100)
                    end
                    drawImage(rs+(BLOCK_SIZE*(x-1)), rs2+(BLOCK_SIZE*(y-(HIDDEN_HEIGHT+1))), block, c)
                end
            end
        end

        local np = game.nextQueue[1]
        if np then
            local nps = pieces[np][1]
            for y=1,#nps do
                for x=1,#nps[y] do
                    local e = nps[y][x]
                    if e ~= 0 then
                        local c = piececolours[np]
                        if not c then
                            c = colours.WHITE
                        end
                        drawImage(re+5+(BLOCK_SIZE*x), rs2+(BLOCK_SIZE*y), block, c)
                    end
                end
            end
        end

        if game.gamestyle == 'extended' then
            for i=2,3 do
                local np = game.nextQueue[i]
                if np then
                    local nps = pieces[np][1]
                    for y=1,#nps do
                        for x=1,#nps[y] do
                            local e = nps[y][x]
                            if e ~= 0 then
                                local c = piececolours[np]
                                if not c then
                                    c = colours.WHITE
                                end
                                drawImage(re+20+(BLOCK_SIZE*4)+((i-2)*(SMALLBLOCK_SIZE*4))+(SMALLBLOCK_SIZE*x)+((i-1)*20)-5, rs2+(SMALLBLOCK_SIZE*y)+20, smallblock, c)
                            end
                        end
                    end
                end
            end

            local hp = game.holdPiece
            if hp then
                local hps = pieces[hp][1]
                for y=1,#hps do
                    for x=1,#hps[y] do
                        local e = hps[y][x]
                        if e ~= 0 then
                            local c = piececolours[hp]
                            if not c then
                                c = colours.WHITE
                            end
                            if not game.holdAvailable then
                                c = newColour(getR(c), getG(c), getB(c), 100)
                            end
                            drawImage(rs-5-(BLOCK_SIZE*4)+(BLOCK_SIZE*(x-1)), rs2+(BLOCK_SIZE*y), block, c)
                        end
                    end
                end
            end
        end

        if game.dead then
            pstring('GAME OVER', 200)
        end

        if mode and mode.draw then
            mode:draw(re+20, re2)
        end
    end

    if state == 'menu' then
        local f = {
            'Master'
        }
        for i, j in ipairs(f) do
            pstring(j, 125 + (i * (FONT_SIZE + 3)), ternary(menuselect == i, colours.GOLD, colours.WHITE))
        end
    end

    if state == 'rotselect' then
        local f = {
            'Classic',
            'World'
        }
        for i, j in ipairs(f) do
            pstring(j, 125 + (i * (FONT_SIZE + 3)), ternary(menuselect == i, colours.GOLD, colours.WHITE))
        end
    end

    if state == 'styleselect' then
        local f = {
            'Standard',
            'Extended'
        }
        for i, j in ipairs(f) do
            pstring(j, 125 + (i * (FONT_SIZE + 3)), ternary(menuselect == i, colours.GOLD, colours.WHITE))
        end
    end

    --Graphics.debugPrint(0, 0, tostring(dt), colours.WHITE)

    compat.afterDraw()
end

while gameLoop(update, draw) do end --hack??