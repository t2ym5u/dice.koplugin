local Blitbuffer      = require("ffi/blitbuffer")
local Font             = require("ui/font")
local Geom             = require("ui/geometry")
local InputContainer   = require("ui/widget/container/inputcontainer")
local RenderText       = require("ui/rendertext")
local UIManager        = require("ui/uimanager")
local _                = require("i18n")
local T                = require("ffi/util").template

local C_BG     = Blitbuffer.COLOR_WHITE
local C_BORDER = Blitbuffer.COLOR_BLACK
local C_PIP    = Blitbuffer.COLOR_BLACK
local C_TEXT   = Blitbuffer.COLOR_BLACK

-- Standard 3x3 pip layout (as fractions of the die's side) for faces 1-6,
-- matching the dot pattern found on a real d6.
local PIP_LAYOUT = {
    [1] = { {0.5,  0.5 } },
    [2] = { {0.25, 0.25}, {0.75, 0.75} },
    [3] = { {0.25, 0.25}, {0.5,  0.5 }, {0.75, 0.75} },
    [4] = { {0.25, 0.25}, {0.75, 0.25}, {0.25, 0.75}, {0.75, 0.75} },
    [5] = { {0.25, 0.25}, {0.75, 0.25}, {0.5, 0.5 }, {0.25, 0.75}, {0.75, 0.75} },
    [6] = { {0.25, 0.25}, {0.75, 0.25}, {0.25, 0.5}, {0.75, 0.5}, {0.25, 0.75}, {0.75, 0.75} },
}

-- Pick the largest font size (<= a soft cap) whose rendering of `label`
-- still fits within a `side`x`side` box.
local function fitNumberFace(side, label)
    local size = math.max(10, math.floor(side * 0.6))
    while size > 8 do
        local face = Font:getFace("cfont", size)
        local m = RenderText:sizeUtf8Text(0, side, face, label, true, false)
        if m.x <= side * 0.8 and (m.y_bottom - m.y_top) <= side * 0.8 then
            return face
        end
        size = size - 1
    end
    return Font:getFace("cfont", 8)
end

-- ---------------------------------------------------------------------------
-- DiceBoardWidget
-- ---------------------------------------------------------------------------

local DiceBoardWidget = InputContainer:extend{
    board      = nil,
    max_width  = 300,
    max_height = 300,
}

function DiceBoardWidget:init()
    self:_layout()
    self.dimen      = Geom:new{ x = 0, y = 0, w = self.w, h = self.h }
    self.paint_rect = Geom:new{ x = 0, y = 0, w = self.w, h = self.h }
end

function DiceBoardWidget:_layout()
    local board = self.board
    local nd    = math.max(1, board.num_dice)
    local mw    = self.max_width
    local mh    = self.max_height

    -- Reserve space for the "Total: N" line when rolling more than one die.
    local sum_h = 0
    if nd > 1 then
        self.sum_face = Font:getFace("cfont", math.max(14, math.floor(math.min(mw, mh) * 0.06)))
        local m = RenderText:sizeUtf8Text(0, mw, self.sum_face, "0", true, false)
        sum_h = (m.y_bottom - m.y_top) + math.floor(mh * 0.04)
    end

    local gap    = math.max(4, math.floor(mw * 0.02))
    local area_h = math.max(10, mh - sum_h)

    -- Try every column count and keep whichever yields the largest die.
    local best_size, best_cols, best_rows = 0, 1, nd
    for cols = 1, nd do
        local rows     = math.ceil(nd / cols)
        local size_w   = math.floor((mw - (cols + 1) * gap) / cols)
        local size_h   = math.floor((area_h - (rows + 1) * gap) / rows)
        local die_size = math.min(size_w, size_h)
        if die_size > best_size then
            best_size, best_cols, best_rows = die_size, cols, rows
        end
    end
    best_size = math.max(best_size, 10)

    self.die_size = best_size
    self.cols     = best_cols
    self.rows     = best_rows
    self.gap      = gap
    self.sum_h    = sum_h

    self.grid_w = best_cols * best_size + (best_cols + 1) * gap
    self.grid_h = best_rows * best_size + (best_rows + 1) * gap

    self.w = self.grid_w
    self.h = self.grid_h + sum_h

    self.num_face = fitNumberFace(best_size, tostring(board.num_faces))
end

function DiceBoardWidget:refresh()
    local rect = self.paint_rect
    UIManager:setDirty(self, function()
        return "ui", Geom:new{ x = rect.x, y = rect.y, w = rect.w, h = rect.h }
    end)
end

function DiceBoardWidget:_drawPips(bb, dx, dy, s, value)
    local layout = PIP_LAYOUT[value]
    if not layout then return end
    local pr = math.max(2, math.floor(s * 0.08))
    for _, p in ipairs(layout) do
        local cx = dx + math.floor(s * p[1])
        local cy = dy + math.floor(s * p[2])
        bb:paintCircle(cx, cy, pr, C_PIP)
    end
end

function DiceBoardWidget:_drawNumber(bb, dx, dy, s, value)
    local label = tostring(value)
    local m  = RenderText:sizeUtf8Text(0, s, self.num_face, label, true, false)
    local tx = dx + math.floor((s - m.x) / 2)
    local ty = dy + math.floor((s - (m.y_bottom - m.y_top)) / 2) + m.y_bottom
    RenderText:renderUtf8Text(bb, tx, ty, self.num_face, label, true, false, C_TEXT)
end

function DiceBoardWidget:paintTo(bb, x, y)
    self.paint_rect = Geom:new{ x = x, y = y, w = self.w, h = self.h }
    local board = self.board
    local nd    = math.max(1, board.num_dice)
    local nf    = board.num_faces
    local results = board.results or {}

    local s        = self.die_size
    local gap      = self.gap
    local border_w = math.max(1, math.floor(s * 0.035))
    local radius   = math.max(2, math.floor(s * 0.15))

    for i = 1, nd do
        local col = (i - 1) % self.cols
        local row = math.floor((i - 1) / self.cols)
        local dx  = x + gap + col * (s + gap)
        local dy  = y + gap + row * (s + gap)
        local value = results[i] or 1

        bb:paintRoundedRect(dx, dy, s, s, C_BG, radius)
        bb:paintBorder(dx, dy, s, s, border_w, C_BORDER, radius)

        if nf == 6 then
            self:_drawPips(bb, dx, dy, s, value)
        else
            self:_drawNumber(bb, dx, dy, s, value)
        end
    end

    if nd > 1 then
        local sum_text = T(_("Total: %1"), board:sum())
        local m  = RenderText:sizeUtf8Text(0, self.w, self.sum_face, sum_text, true, false)
        local sx = x + math.floor((self.w - m.x) / 2)
        local sy = y + self.grid_h + m.y_bottom
        RenderText:renderUtf8Text(bb, sx, sy, self.sum_face, sum_text, true, false, C_TEXT)
    end
end

return DiceBoardWidget
