-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local items = Items()
    if #items == 0 then return end
    items:Unselect()
    local num = 0
    local initTrack
    local initItem
    for i, item in ipairs(items) do
        local track = item.track
        local take = item.take
        if take then
            if track == initTrack then
                if take.srcfile == initItem.srcfile then
                    num = num + 1
                    if num > 1 then
                        initItem.take:SetTakeMarker(-1, tostring(num), take.offset + item.snapoffset * take.playrate)
                    end
                    if i > 1 then item:Delete() end
                else
                    item:Select()
                end
            else
                if num > 1 then
                    initItem.take:SetTakeMarker(-1, '1', initItem.offset + initItem.snapoffset * initItem.playrate)
                end
                initTrack = track
                initItem = item
                initItem:Select()
                num = 1
            end
        end
    end
    if num > 1 then initItem.take:SetTakeMarker(-1, '1', initItem.offset + initItem.snapoffset * initItem.playrate) end
    r.Main_OnCommand(40543, 0) -- Take: Implode items on same track into takes
end)
