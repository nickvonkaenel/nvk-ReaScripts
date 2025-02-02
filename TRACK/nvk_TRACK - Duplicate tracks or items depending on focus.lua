-- @noindex
-- Depending on the last click of the mouse, this script will duplicate selected tracks, items, or automation items. It also handles the issue where item group ids stay the same when duplicating tracks which is generally undesired behavior
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local context = reaper.GetCursorContext()
    if context == 0 then
        reaper.Main_OnCommand(40062, 0)
        -- Duplicating tracks will link groups, which is generally not what we want
        for _, group in ipairs(Tracks.Selected():Items().groups) do
            group.groupid = math.random(1, 0x7FFFFFFF) -- 0 is no group, 0x7FFFFFFF is the max positive value for a 32-bit integer
        end
        scr.name = 'Track: Duplicate tracks'
    elseif context == 1 then
        local s, e = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
        if s == e then
            reaper.Main_OnCommand(41295, 0)
            scr.name = 'Item: Duplicate items'
        else
            reaper.Main_OnCommand(41296, 0)
            scr.name = 'Item: Duplicate selected area of items'
        end
    elseif context == 2 then
        reaper.Main_OnCommand(42085, 0)
        scr.name = 'Envelope: Duplicate and pool automation items'
    end
end)
