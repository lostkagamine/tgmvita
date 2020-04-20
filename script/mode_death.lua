--[[
    public locks: number[] = [30, 26, 22, 18, 15];
    public locklevels: number[] = [101, 201, 301, 401];
    
    public ares: number[] = [18, 14, 8, 7, 6];
    public arelevels: number[] = [101, 301, 401, 500];

                                // counting clear ARE
    public lineares: number[] = [14+12, 8+6, 7+5, 6+4];
    public linearelevels: number[] = [101, 401, 500];

    public dases: number[] = [12, 11, 10, 8];
    public daslevels: number[] = [200, 300, 400];
]]

local locks = {
    30, 26, 22, 18, 15
}

local locklevels = {
    101, 201, 301, 401, 99999
}

local ares = {
    18, 14, 8, 7, 6
}

local arelevels = {
    101, 301, 401, 500, 99999
}

local lares = {
    14, 8, 7, 6
}

local larelevels = {
    101, 401, 500, 99999
}

local dases = {
    12, 11, 10, 8
}

local daslevels = {
    200, 300, 400, 99999
}

local clears = {
    12, 6, 5, 4
}

local clearlevels = {
    101, 401, 500, 99999
}

mode = {
    init = function(self, style)
        game.delays.are = 18 * (1/60)
        game.delays.das = 12 * (1/60)
        game.delays.lock = 30 * (1/60)
        game.delays.lare = 14 * (1/60)
        game.delays.clear = 12 * (1/60)
        game.delays.gravity = 20
        self.lockptr = 1
        self.areptr = 1
        self.lareptr = 1
        self.dasptr = 1
        self.clearptr = 1

        self.grade = ""
    end,
    setDelays = function(self)
        if self.grade == "" and game.level >= 500 then
            if cTimer.getTime(game.timer) > 205000 then
                game:gameOver()
                return
            end
            self.grade = "M"
            playSound(audio.gradeup)
        end

        if game.level >= game.endlevel then
            self.grade = "Gm"
            playSound(audio.gameclear)
            game:gameOver()
        end

        if game.level >= locklevels[self.lockptr] then
            self.lockptr = self.lockptr + 1
        end
        game.delays.lock = locks[self.lockptr] * (1/60)

        if game.level >= arelevels[self.areptr] then
            self.areptr = self.areptr + 1
        end
        game.delays.are = ares[self.areptr] * (1/60)

        if game.level >= larelevels[self.lareptr] then
            self.lareptr = self.lareptr + 1
        end
        game.delays.lare = lares[self.lareptr] * (1/60)

        if game.level >= daslevels[self.dasptr] then
            self.dasptr = self.dasptr + 1
        end
        game.delays.das = dases[self.dasptr] * (1/60)

        if game.level >= clearlevels[self.clearptr] then
            self.clearptr = self.clearptr + 1
        end
        game.delays.das = clears[self.clearptr] * (1/60)
    end,
    clear = function(self, lines)

    end,
    draw = function(self, rf, re2)
        fontPrint(font, rf, re2-300, self.grade, colours.GOLD)
    end
}