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
    local retval, retvals_csv = r.GetUserInputs('Reposition Items', 1, 'Time (negative to use item end)', '0')
    if retval == false then return end
    local repositionTime = tonumber(retvals_csv)
    if not repositionTime then return end
    local startTime, endTime = r.BR_GetArrangeView(0)
    local cursorPos = r.GetCursorPosition()
    local groupingToggle = r.GetToggleCommandState(1156) == 1
    if groupingToggle then
        r.Main_OnCommand(1156, 0) -- grouping override
    end
    RepositionSelectedItems(repositionTime)
    r.SetEditCurPos(cursorPos, false, false)
    r.BR_SetArrangeView(0, startTime, endTime)
    if groupingToggle then
        r.Main_OnCommand(1156, 0) -- grouping override
    end
end)
