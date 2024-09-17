-- @noindex
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local tracks = Tracks()
    if #tracks == 0 then
        local track = Track(r.GetLastTouchedTrack())
        if track then
            tracks = Tracks { track }
        else
            local items = Items()
            if #items == 0 then return end
            tracks = Tracks(items.tracks)
        end
    end
    local columns = tracks:Columns()
    if #columns == 0 then return end
    local cursorPos = r.GetCursorPosition()
    for i = #columns, 1, -1 do
        local column = columns[i]
        if column.s < cursorPos then
            column.items:Select(true)
            if column.e >= cursorPos then
                r.Main_OnCommand(40376, 0) -- Item navigation: Move cursor to previous transient in items
                if cursorPos == r.GetCursorPosition() then r.SetEditCurPos(column.s, true, true) end
            else
                r.SetEditCurPos(column.e, true, true)
            end
            for _, item in ipairs(column.items) do
                if item.folder then item:GroupSelect(true) end
            end
            return
        end
    end
end)
