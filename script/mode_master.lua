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

mode = {
    init = function(self)
        game.delays.are = 30 * (1/60)
        game.delays.das = 16 * (1/60)
        game.delays.lock = 30 * (1/60)
        game.delays.lare = game.delays.are
        game.delays.clear = 41 * (1/60)
        game.delays.gravity = 4/256
        self.pointer = 1
    end,
    setDelays = function(self)
        if game.level >= gravlevels[self.pointer] then
            self.pointer = self.pointer + 1
        end
        game.delays.gravity = gravtable[self.pointer] / 256
    end
}