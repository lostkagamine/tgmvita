local BLANK = {0, 0, 0, 0}

pieces = {
    I = {
        { BLANK,
            {1, 1, 1, 1},
            BLANK,
            BLANK },
        { {0, 0, 1, 0},
            {0, 0, 1, 0},
            {0, 0, 1, 0},
            {0, 0, 1, 0} }
    },
    T = {
        {{0, 0, 0},
         {1, 1, 1},
         {0, 1, 0}},
        {{0, 1, 0},
         {1, 1, 0},
         {0, 1, 0}},
        {{0, 0, 0},
         {0, 1, 0},
         {1, 1, 1}},
        {{0, 1, 0},
         {0, 1, 1},
         {0, 1, 0}}
    },
    S = {
        {{0, 0, 0},
         {0, 1, 1},
         {1, 1, 0}},
        {{1, 0, 0},
         {1, 1, 0},
         {0, 1, 0}}
    },
    Z = {
        {{0,0,0},
         {1, 1, 0},
         {0, 1, 1}},
        {{0, 0, 1},
         {0, 1, 1},
         {0, 1, 0}}
    },
    J = {
        {{0,0,0},
         {1, 1, 1,},
         {0, 0, 1,}},
        {{0, 1, 0,},
         {0, 1, 0,},
         {1, 1, 0}},
        {{0,0,0},
         {1, 0, 0},
         {1, 1, 1}},
        {{0, 1, 1},
         {0, 1, 0},
         {0, 1, 0}}
    },
    L = {
        {{0, 0, 0},
         {1, 1, 1},
         {1, 0, 0}},
        {{1, 1, 0},
         {0, 1, 0},
         {0, 1, 0}},
        {{0, 0, 0},
         {0, 0, 1},
         {1, 1, 1}},
        {{0, 1, 0,},
         {0, 1, 0,},
         {0, 1, 1,}}
    },
    O = {
        {{0, 0},
         {1, 1},
         {1, 1}},
    }
}

piececolours = {
    I = newColour(255, 55, 55),
    O = newColour(255, 255, 55),
    J = newColour(55, 55, 255),
    T = newColour(55, 255, 255),
    Z = newColour(55, 255, 55),
    S = newColour(255, 55, 255),
    L = newColour(255, 155, 55),
    FLAT = newColour(255, 255, 255),
}

function game_wallkick(game, piecest, a, b)
    local failed = true
    local change = 0
    if game.piece.name == "I" then return true, 0, 0 end
    local middlepieces = {'T', 'J', 'L'}
    if tableindex(middlepieces, game.piece.name) ~= -1 then
        -- middle column rule!
        for y=0,2 do
            local brk = false
            for x=0,2 do
                local b = game:hasBlock(game.x+x, game.y+y)
                if b ~= 0 then
                    if x == 1 then
                        return true, 0, 0
                    else
                        brk = true
                        break
                    end
                end
            end
            if brk then
                break
            end
        end
    end
    if not game:isColliding(piecest, game.x+1) then -- mihara's conspiracy
        change = 1
        failed = false
    end
    if not game:isColliding(piecest, game.x-1) then
        change = -1
        failed = false
    end
    return failed, change, 0
end

WORLD_RULE = false
REVERSE_ROTATIONS = false