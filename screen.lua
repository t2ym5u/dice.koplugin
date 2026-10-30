local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local Geom            = require("ui/geometry")
local GestureRange    = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan  = require("ui/widget/horizontalspan")
local InputDialog     = require("ui/widget/inputdialog")
local Size            = require("ui/size")
local UIManager       = require("ui/uimanager")
local VerticalGroup   = require("ui/widget/verticalgroup")
local VerticalSpan    = require("ui/widget/verticalspan")
local _               = require("i18n")
local T               = require("ffi/util").template

local ScreenBase = require("screen_base")
local MenuHelper = require("menu_helper")

local DiceBoard       = lrequire("board")
local DiceBoardWidget = lrequire("board_widget")

local FACE_PRESETS = { 4, 6, 8, 10, 12, 20 }

local GAME_RULES_EN = _([[
Dice — Rules

Pick how many dice to roll and how many faces each one has (top-left menu), then tap "Roll".

• 6-sided dice are drawn with real pips, just like a physical die.
• Any other face count shows the rolled number on the die instead.
• The total of all dice is shown below the roll whenever you use more than one die.
• Your last roll and settings are remembered the next time you open Dice.
]])

local GAME_RULES_FR = [[
Dés — Règles

Choisissez le nombre de dés à lancer et leur nombre de faces (menu en haut à gauche), puis appuyez sur « Lancer ».

• Les dés à 6 faces sont dessinés avec de vrais points, comme un dé physique.
• Tout autre nombre de faces affiche le chiffre obtenu sur le dé.
• Le total de tous les dés est affiché sous le lancer dès que vous utilisez plus d'un dé.
• Votre dernier lancer et vos réglages sont mémorisés à la prochaine ouverture.
]]

-- ---------------------------------------------------------------------------
-- DiceScreen
-- ---------------------------------------------------------------------------

local DiceScreen = ScreenBase:extend{}

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function DiceScreen:init()
    local state = self.plugin:loadState()
    self.board = DiceBoard:new()
    self.board:load(state)
    ScreenBase.init(self)
end

function DiceScreen:serializeState()
    return self.board:serialize()
end

-- ---------------------------------------------------------------------------
-- Layout
-- ---------------------------------------------------------------------------

function DiceScreen:buildLayout()
    local is_landscape = self:isLandscape()

    local title_bar = self:buildTitleBar(_("Dice"), function()
        return {
            { text = T(_("Faces: %1"), "d" .. self.board.num_faces), callback = function() self:openFacesMenu() end },
            { text = T(_("Dice: %1"), self.board.num_dice),          callback = function() self:openDiceMenu()  end },
            self:makeRulesButtonConfig(GAME_RULES_EN, GAME_RULES_FR),
        }
    end)

    self.status_text:setMaxWidth(self:getControlsWidth())
    local controls = VerticalGroup:new{
        align = "center",
        self.status_text,
        VerticalSpan:new{ width = Size.span.vertical_large },
        self:buildActionBar({
            -- Plain label: the UI fonts have no glyph for the 🎲 emoji
            -- that used to prefix it, so it rendered as a missing-glyph box.
            { text = _("Roll"), callback = function() self:onRoll() end },
        }),
    }

    local budget_w, budget_h = self:getBoardBudget(title_bar, controls)
    self.board_widget = DiceBoardWidget:new{
        board      = self.board,
        max_width  = budget_w,
        max_height = budget_h,
    }

    if is_landscape then
        self:buildLandscapeLayout(title_bar, HorizontalGroup:new{
            align = "center",
            self.board_widget,
            HorizontalSpan:new{ width = self:getGutter() },
            controls,
        })
    else
        self:buildPortraitLayout(title_bar, self.board_widget,
            VerticalGroup:new{ align = "center", controls, VerticalSpan:new{ width = self:getGutter() } })
    end
    self:updateStatus()

    -- Let any tap outside the header roll the dice, not just the button.
    local header_h = title_bar:getSize().h
    local self_ref = self
    self.ges_events = {
        TapToRoll = { GestureRange:new{
            ges   = "tap",
            range = function()
                return Geom:new{
                    x = self_ref.dimen.x,
                    y = self_ref.dimen.y + header_h,
                    w = self_ref.dimen.w,
                    h = self_ref.dimen.h - header_h,
                }
            end,
        } },
    }
end

function DiceScreen:onTapToRoll()
    self:onRoll()
    return true
end

-- ---------------------------------------------------------------------------
-- Rolling
-- ---------------------------------------------------------------------------

function DiceScreen:onRoll()
    self.board:roll()
    self.plugin:saveState(self.board:serialize())
    self.board_widget:refresh()
    self:updateStatus()
end

-- ---------------------------------------------------------------------------
-- Number of faces
-- ---------------------------------------------------------------------------

function DiceScreen:openFacesMenu()
    local items = {}
    for _, f in ipairs(FACE_PRESETS) do
        items[#items + 1] = { id = f, text = "d" .. f }
    end
    items[#items + 1] = { id = "custom", text = _("Custom…") }

    local current   = self.board.num_faces
    local is_preset = false
    for _, f in ipairs(FACE_PRESETS) do
        if f == current then is_preset = true break end
    end

    MenuHelper.openPickerMenu{
        title      = _("Faces"),
        items      = items,
        current_id = is_preset and current or nil,
        parent     = self,
        on_select  = function(id)
            if id == "custom" then
                self:openCustomFacesDialog()
            else
                self:applyFaces(id)
            end
        end,
    }
end

function DiceScreen:openCustomFacesDialog()
    local dialog
    dialog = InputDialog:new{
        title      = _("Custom number of faces"),
        input      = tostring(self.board.num_faces),
        input_hint = T(_("%1–%2"), DiceBoard.MIN_FACES, DiceBoard.MAX_FACES),
        input_type = "number",
        buttons    = {
            {
                {
                    text     = _("Cancel"),
                    id       = "close",
                    callback = function() UIManager:close(dialog) end,
                },
                {
                    text = _("OK"),
                    is_enter_default = true,
                    callback = function()
                        local n = dialog:getInputValue()
                        UIManager:close(dialog)
                        if n then self:applyFaces(n) end
                    end,
                },
            },
        },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

function DiceScreen:applyFaces(n)
    self.board:setNumFaces(n)
    self.board:roll()
    self.plugin:saveState(self.board:serialize())
    self:buildLayout()
    UIManager:setDirty(self, function() return "ui", self.dimen end)
end

-- ---------------------------------------------------------------------------
-- Number of dice
-- ---------------------------------------------------------------------------

function DiceScreen:openDiceMenu()
    local items = {}
    for n = DiceBoard.MIN_DICE, DiceBoard.MAX_DICE do
        items[#items + 1] = { id = n, text = T(_("%1 dice"), n) }
    end
    MenuHelper.openPickerMenu{
        title      = _("Dice"),
        items      = items,
        current_id = self.board.num_dice,
        parent     = self,
        on_select  = function(n) self:applyDiceCount(n) end,
    }
end

function DiceScreen:applyDiceCount(n)
    self.board:setNumDice(n)
    self.board:roll()
    self.plugin:saveState(self.board:serialize())
    self:buildLayout()
    UIManager:setDirty(self, function() return "ui", self.dimen end)
end

-- ---------------------------------------------------------------------------
-- Status bar
-- ---------------------------------------------------------------------------

function DiceScreen:updateStatus()
    local status = self:joinStatus(T(_("%1 dice"), self.board.num_dice), "d" .. self.board.num_faces)
    ScreenBase.updateStatus(self, status)
end

return DiceScreen
