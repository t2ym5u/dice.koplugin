local DIR = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
package.path = DIR .. "?.lua;" .. package.path

describe("DiceBoard", function()
    local Board

    setup(function()
        Board = require("board")
    end)

    describe("new", function()
        it("defaults to 2 dice with 6 faces, already rolled", function()
            local b = Board:new()
            assert.are.equal(2, b.num_dice)
            assert.are.equal(6, b.num_faces)
            assert.are.equal(2, #b.results)
            for _, v in ipairs(b.results) do
                assert.is_true(v >= 1 and v <= 6)
            end
        end)
    end)

    describe("setNumDice / setNumFaces", function()
        it("clamps num_dice to [MIN_DICE, MAX_DICE]", function()
            local b = Board:new()
            b:setNumDice(0)
            assert.are.equal(Board.MIN_DICE, b.num_dice)
            b:setNumDice(999)
            assert.are.equal(Board.MAX_DICE, b.num_dice)
        end)

        it("clamps num_faces to [MIN_FACES, MAX_FACES]", function()
            local b = Board:new()
            b:setNumFaces(1)
            assert.are.equal(Board.MIN_FACES, b.num_faces)
            b:setNumFaces(9999)
            assert.are.equal(Board.MAX_FACES, b.num_faces)
        end)
    end)

    describe("roll / sum", function()
        it("rolls exactly num_dice results within [1, num_faces]", function()
            local b = Board:new()
            b:setNumDice(5)
            b:setNumFaces(10)
            local results = b:roll()
            assert.are.equal(5, #results)
            for _, v in ipairs(results) do
                assert.is_true(v >= 1 and v <= 10)
            end
        end)

        it("sum adds up all current results", function()
            local b = Board:new()
            b.results = { 3, 4 }
            assert.are.equal(7, b:sum())
        end)
    end)

    describe("serialize / load", function()
        it("round-trips dice count, faces and results", function()
            local b = Board:new()
            b:setNumDice(4)
            b:setNumFaces(8)
            b:roll()
            local data = b:serialize()

            local b2 = Board:new()
            assert.is_true(b2:load(data))
            assert.are.equal(4, b2.num_dice)
            assert.are.equal(8, b2.num_faces)
            assert.are.same(b.results, b2.results)
        end)

        it("re-rolls when the stored results don't match num_dice", function()
            local b = Board:new()
            assert.is_true(b:load({ num_dice = 3, num_faces = 6, results = { 1, 2 } }))
            assert.are.equal(3, #b.results)
        end)

        it("returns false for non-table data", function()
            local b = Board:new()
            assert.is_false(b:load(nil))
        end)
    end)
end)
