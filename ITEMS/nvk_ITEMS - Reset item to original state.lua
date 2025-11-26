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
    local xStart, xEnd = r.GetSet_ArrangeView2(0, false, 0, 0)
    local cursorPos = r.GetCursorPosition()
    for _, item in ipairs(Items()) do
        local itemPos = item.pos
        item.track:SetLastTouched()
        local file = item.srcfile
        if file then
            item:Delete()
            r.SetEditCurPos(itemPos, false, false)
            r.InsertMedia(file, 0)
        end
    end
    r.SetEditCurPos(cursorPos, false, false)
    r.GetSet_ArrangeView2(0, true, 0, 0, xStart, xEnd)
end)
