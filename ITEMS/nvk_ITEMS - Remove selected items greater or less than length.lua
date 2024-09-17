-- @noindex
-- USER CONFIG --
DEFAULT_LESS = 0
DEFAULT_GREATER = 300
-- SETUP --
SCRIPT_FOLDER = 'simple'
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
table.insert(bar.buttons, 1, 'pin')

local less, greater = DEFAULT_LESS, DEFAULT_GREATER

SimpleDraw = function()
    local rv
    rv, less, greater = ImGui.DragFloatRange2(
        ctx,
        'Length',
        less,
        greater,
        nil,
        0,
        300,
        '%.1f seconds',
        '%.1f seconds',
        ImGui.SliderFlags_Logarithmic | ImGui.SliderFlags_NoRoundToFormat
    )
    local items = Items():Filter(function(item) return item.len < less or item.len > greater end)
    ImGui.Spacing(ctx)
    ImGui.Spacing(ctx)
    ImGui.Spacing(ctx)
    if ImGui.Button(ctx, 'Remove ' .. #items .. ' items') then Actions.Run() end
end

SimpleRun = function()
    Items():Filter(function(item) return item.len < less or item.len > greater end):Delete()
end
