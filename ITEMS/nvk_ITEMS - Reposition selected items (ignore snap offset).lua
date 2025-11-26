-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    if r.CountSelectedMediaItems() > 0 then
        local retval, retvals_csv = r.GetUserInputs('Reposition Items', 1, 'Time (negative to use item end)', '0')
        if retval == false then return end
        local items = {}
        for i = 1, r.CountSelectedMediaItems() do
            local item = r.GetSelectedMediaItem(0, i - 1)
            items[i] = { item, r.GetMediaItemInfo_Value(item, 'D_SNAPOFFSET') }
            r.SetMediaItemInfo_Value(item, 'D_SNAPOFFSET', 0)
        end
        r.UpdateArrange()
        local repositionTime = tonumber(retvals_csv)
        if not repositionTime then return end
        local startTime, endTime = r.BR_GetArrangeView(0)
        local cursorPos = r.GetCursorPosition()
        local groupingToggle = r.GetToggleCommandState(1156) == 1
        if groupingToggle then r.Main_OnCommand(1156, 0) end
        RepositionSelectedItems(repositionTime)
        r.SetEditCurPos(cursorPos, false, false)
        r.BR_SetArrangeView(0, startTime, endTime)
        if groupingToggle then r.Main_OnCommand(1156, 0) end
        for i = 1, #items do
            r.SetMediaItemInfo_Value(items[i][1], 'D_SNAPOFFSET', items[i][2])
        end
    end
end)
