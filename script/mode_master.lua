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
    "9", "8", "7", "6", "5", "4", "3", "2", "1",
    "S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "Gm"
}

local gradepoints = {
    400, 800, 1400, 2000, 3500, 5500, 8000, 12000, 16000, 22000, 30000,
    40000, 52000, 66000, 82000, 100000, 120000, math.huge, math.huge
}

mode = {
    init = function(self, style)
        game.delays.are = 30 * (1/60)
        game.delays.das = 16 * (1/60)
        game.delays.lock = 30 * (1/60)
        game.delays.lare = game.delays.are
        game.delays.clear = 41 * (1/60)
        game.delays.gravity = 4/256
        self.pointer = 1

        self.combo = 1
        self.score = 0

        self.grade = 1

        if not WORLD_RULE and style == 'classic' then
            game.blockSonic = true
        end

        self.gm300 = false
        self.gm500 = false
        self.checked300 = false
        self.checked500 = false
    end,
    setDelays = function(self)
        if not self.checked300 and game.level >= 300 and self.score >= 12000 and cTimer.getTime(game.timer) <= 255000 then
            self.gm300 = true
            self.checked300 = true
        end
        if not self.checked500 and game.level >= 500 and self.score >= 40000 and cTimer.getTime(game.timer) <= 450000 then
            self.gm500 = true
            self.checked500 = true
        end

        if game.level >= 100 then
            game.drawGhost = false
        end

        if game.level >= game.endlevel then
            if self.gm500 and self.gm300 and self.score >= 126000 and cTimer.getTime(game.timer) <= 810000 then
                -- GRAND MASTER!!
                self.grade = 19
                playSound(audio.gameclear)
            end

            game:gameOver()
        end

        if game.level >= gravlevels[self.pointer] then
            self.pointer = self.pointer + 1
        end
        game.delays.gravity = gravtable[self.pointer] / 256
    end,
    clear = function(self, lines)
        if lines == 0 then
            self.combo = 1
        else
            self.combo = self.combo + (2*lines) - 2
        end
        local bravo = 1 
        if game:hasPerfectCleared() then
            bravo = 4
        end
        if lines >= 1 then
            local add = (math.ceil((game.level + lines) / 4) + game.softDropFrames) * lines * self.combo * bravo
            self.score = self.score + add
        end

        while self.score >= gradepoints[self.grade] do
            self.grade = self.grade + 1
            playSound(audio.gradeup)
        end
    end,
    draw = function(self, rf, re2)
        fontPrint(font, rf, re2-300, gradenames[self.grade], colours.WHITE)
        local g = gradepoints[self.grade]
        if g == math.huge then
            g = '??????'
        else
            g = tostring(g)
        end
        fontPrint(font, rf, re2-220, g, colours.WHITE)
        fontPrint(font, rf, re2-250, tostring(self.score), colours.WHITE)
    end
}