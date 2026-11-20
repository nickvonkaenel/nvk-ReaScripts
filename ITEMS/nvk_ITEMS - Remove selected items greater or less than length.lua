-- @noindex
-- USER CONFIG --
DEFAULT_LESS = 0
DEFAULT_GREATER = 300
-- SETUP --
SCRIPT_FOLDER = 'simple'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
table.insert(bar.buttons, 1, 'pin')

local less, greater = DEFAULT_LESS, DEFAULT_GREATER

-- The button's count, read once per change: this draws every frame, and the selection can be thousands of items.
local counted = {}
local function count_items_to_remove()
    local state, selected = r.GetProjectStateChangeCount(0), r.CountSelectedMediaItems(0)
    if counted.state ~= state or counted.selected ~= selected or counted.less ~= less or counted.greater ~= greater then
        local count = 0
        for i = 0, selected - 1 do
            local len = r.GetMediaItemInfo_Value(r.GetSelectedMediaItem(0, i), 'D_LENGTH')
            if len < less or len > greater then
                count = count + 1
            end
        end
        counted = { state = state, selected = selected, less = less, greater = greater, count = count }
    end
    return counted.count
end

function SimpleDraw()
    local rv
    ImGui.PushFont(ctx, FONT.tabular, ImGui.GetFontSize(ctx))
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
    ImGui.PopFont(ctx)
    local count = count_items_to_remove()
    ImGui.Spacing(ctx)
    ImGui.Spacing(ctx)
    ImGui.Spacing(ctx)
    if gui.Clickable(ImGui.Button(ctx, 'Remove ' .. count .. ' items')) then
        Actions.Run()
    end
end

function SimpleRun()
    Items():Filter(function(item)
        return item.len < less or item.len > greater
    end):Delete()
end
