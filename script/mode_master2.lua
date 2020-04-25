local gravtable = {
    4, 6, 8, 10, 12, 16, 32, 48, 64, 80, 96, 112, 128, 144,
    4, 32, 64, 96, 128, 160, 192, 224, 256, 512, 768, 1024, 1280,
    1024, 768, 5120
}

local gravlevels = {
    30, 35, 40, 50, 60, 70, 80, 90, 100, 120, 140, 160, 170, 200,
    220, 230, 233, 236, 239, 243, 247, 251, 300, 330, 360, 400, 420,
    450, 500, 9999
}

local gradenames = {
    "9", "8", "7", "6", "5", "4", "4", "3", "3", "2", "2", "2",
    "1", "1", "1", "S1", "S1", "S1", "S2", "S3", "S4", "S4", "S4",
    "S5", "S5", "S6", "S6", "S7", "S7", "S8", "S8", "S9"
}

local extendedgrades = {
    "9", "8", "7", "6", "5", "4", "4+", "3", "3+", "2-", "2", "2+",
    "1-", "1", "1+", "S1-", "S1", "S1+", "S2", "S3", "S4-", "S4", "S4+",
    "S5", "S5+", "S6", "S6+", "S7", "S7+", "S8", "S8+", "S9"
}

local locks = {
    30, 30, 30, 30, 30, 17
}

local ares = {
    27, 27, 27, 18, 14, 14
}

local lares = {
    27, 27, 18, 14, 8, 8
}

local dases = {
    16, 10, 10, 10, 10, 8
}

local clears = {
    40, 25, 16, 12, 6, 6
}

local lvls = {
    500, 601, 701, 801, 901, 99999
}


local function decayrate(f) -- shut up, this is probably the best way to do this.
    if f==0 then
        return 125
    elseif f<=2 then
        return 80
    elseif f==3 then
        return 50
    elseif f<=6 then
        return 45
    elseif f<=11 then
        return 40
    elseif f<=14 then
        return 30
    elseif f<=19 then
        return 20
    elseif f<=29 then
        return 15
    else 
        return 10
    end
end

local TAP_OFF_BY_ONE = true -- disable this for when you do TGM3 so the grades dont get fucked up

local combotable = {
    {1, 1, 1},
    {1.2, 1.4, 1.5},
    {1.2, 1.5, 1.8},
    {1.4, 1.6, 2},
    {1.4, 1.7, 2.2},
    {1.4, 1.8, 2.3},
    {1.4, 1.9, 2.4},
    {1.5, 2, 2.5},
    {1.5, 2.1, 2.6},
    {2, 2.5, 3}
}

local baseclear = {
    {10, 20, 40, 50},
    {10, 20, 30, 40},
    {10, 20, 30, 40},
    {10, 15, 30, 40},
    {10, 15, 20, 40},
    {5, 15, 20, 30},
    {5, 10, 20, 30},
    {5, 10, 15, 30},
    {5, 10, 15, 30},
    {5, 10, 15, 30},
    {2, 12, 13, 30}
}

local function getbaseclear(lines, ig)
    if ig >= 10 then
        return ({2, 12, 13, 30})[lines]
    end
    return baseclear[ig+1][lines]
end

local function calcpts(lines, combo, ig)
    local combomult = 1
    if combo >= 1 then
        local al = lines
        if TAP_OFF_BY_ONE then
            al = lines + 1 
            if lines == 4 then al = 1 end
        end
        combomult = combotable[combo+1][al]
    end
    local bc = getbaseclear(lines, ig)
    local p = math.ceil(bc * combomult) * (1 + math.floor(game.level / 250))
    return p
end

mode = {
    init = function(self, style)
        game.delays.are = 27 * (1/60)
        game.delays.das = 16 * (1/60)
        game.delays.lock = 30 * (1/60)
        game.delays.lare = game.delays.are
        game.delays.clear = 40 * (1/60)
        game.delays.gravity = 4/256
        self.pointer = 1

        self.speedptr = 1

        self.combo = 1
        self.score = 0

        self.gradepoints = 0
        self.decay = 0
        self.internalgrade = 0

        self.gradename = "9"
        self.lastgradename = "9"

        self.combo = 0
    end,
    setDelays = function(self)
        if game.level >= 100 then
            game.drawGhost = false
        end

        if game.level >= game.endlevel then
            game:gameOver()
        end

        if game.level >= gravlevels[self.pointer] then
            self.pointer = self.pointer + 1
        end
        game.delays.gravity = gravtable[self.pointer] / 256

        if game.level >= lvls[self.speedptr] then
            self.speedptr = self.speedptr + 1
        end
        game.delays.are = ares[self.speedptr] * (1/60)
        game.delays.lock = locks[self.speedptr] * (1/60)
        game.delays.lare = lares[self.speedptr] * (1/60)
        game.delays.das = dases[self.speedptr] * (1/60)
        game.delays.clear = clears[self.speedptr] * (1/60)
    end,
    clear = function(self, lines)
        if lines >= 1 then
            self.gradepoints = self.gradepoints + calcpts(lines, self.combo, self.internalgrade)
            if self.gradepoints >= 100 then
                self.internalgrade = self.internalgrade + 1
                self.gradepoints = 0
                self.decay = 0
                self.gradename = gradenames[self.internalgrade+1]
                if self.gradename ~= self.lastgradename then
                    playSound(audio.gradeup)
                    self.lastgradename = self.gradename
                end
            end
        end
        if lines >= 2 then
            self.combo = self.combo + 1
        elseif lines == 0 then
            self.combo = 0
        end
    end,
    update = function(self)
        if self.gradepoints > 0 and game.pieceActive and self.combo == 0 then
            -- calc decay
            local fuck = decayrate(self.internalgrade)
            self.decay = self.decay + 1
            if self.decay >= fuck then
                self.gradepoints = self.gradepoints - 1
                self.decay = 0
            end
        end
    end,
    draw = function(self, rf, re2)
        dbgprint(("PTS=%d\nGRD=%s\nDCY=%d\nCOM=%d"):format(self.gradepoints, extendedgrades[self.internalgrade+1], self.decay, self.combo))
        fontPrint(font, rf, re2-300, self.gradename, colours.WHITE)
    end
}