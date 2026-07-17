-- ---------------------------------------------------------------------------
-- DiceBoard — pure dice-rolling logic (no UI)
-- ---------------------------------------------------------------------------

local DiceBoard = {}
DiceBoard.__index = DiceBoard

local MIN_DICE      = 1
local MAX_DICE      = 12
local MIN_FACES     = 2
local MAX_FACES     = 100
local DEFAULT_DICE  = 2
local DEFAULT_FACES = 6

function DiceBoard:new()
    local o = setmetatable({}, self)
    o.num_dice  = DEFAULT_DICE
    o.num_faces = DEFAULT_FACES
    o.results   = {}
    o:roll()
    return o
end

function DiceBoard:setNumDice(n)
    n = math.floor(tonumber(n) or DEFAULT_DICE)
    self.num_dice = math.max(MIN_DICE, math.min(MAX_DICE, n))
end

function DiceBoard:setNumFaces(n)
    n = math.floor(tonumber(n) or DEFAULT_FACES)
    self.num_faces = math.max(MIN_FACES, math.min(MAX_FACES, n))
end

function DiceBoard:roll()
    local results = {}
    for i = 1, self.num_dice do
        results[i] = math.random(self.num_faces)
    end
    self.results = results
    return results
end

function DiceBoard:sum()
    local s = 0
    for _, v in ipairs(self.results) do
        s = s + v
    end
    return s
end

function DiceBoard:serialize()
    return {
        num_dice  = self.num_dice,
        num_faces = self.num_faces,
        results   = self.results,
    }
end

function DiceBoard:load(data)
    if type(data) ~= "table" then return false end
    self:setNumDice(data.num_dice or DEFAULT_DICE)
    self:setNumFaces(data.num_faces or DEFAULT_FACES)

    local results = {}
    for i, v in ipairs(data.results or {}) do
        results[i] = v
    end
    if #results ~= self.num_dice then
        self:roll()
    else
        self.results = results
    end
    return true
end

DiceBoard.MIN_DICE      = MIN_DICE
DiceBoard.MAX_DICE      = MAX_DICE
DiceBoard.MIN_FACES     = MIN_FACES
DiceBoard.MAX_FACES     = MAX_FACES
DiceBoard.DEFAULT_DICE  = DEFAULT_DICE
DiceBoard.DEFAULT_FACES = DEFAULT_FACES

return DiceBoard
