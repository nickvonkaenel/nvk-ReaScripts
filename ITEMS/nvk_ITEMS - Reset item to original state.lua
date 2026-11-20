-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
run(function()
    local xStart, xEnd = r.GetSet_ArrangeView2(0, false, 0, 0)
    local cursorPos = r.GetCursorPosition()
    local tracks = Tracks()
    for _, item in ipairs(Items()) do
        local itemPos = item.pos
        local take = item.take
        local file = take and GetSourceFile(take.take)
        -- Only an item that can come back again is replaced: InsertMedia makes nothing without a file.
        if file and r.file_exists(file) then
            item.track:SetLastTouched()
            item:Delete()
            r.SetEditCurPos(itemPos, false, false)
            r.InsertMedia(file, 0)
        end
    end
    tracks:Select(true)
    r.SetEditCurPos(cursorPos, false, false)
    r.GetSet_ArrangeView2(0, true, 0, 0, xStart, xEnd)
end)
