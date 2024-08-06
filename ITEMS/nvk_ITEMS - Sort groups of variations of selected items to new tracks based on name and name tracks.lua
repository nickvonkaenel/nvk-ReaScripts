-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local itemNames = {}
    local itemCount = r.CountSelectedMediaItems(0)
    if itemCount == 0 then
        return
    end
    local initItem = r.GetSelectedMediaItem(0, 0)
    local initPos = r.GetMediaItemInfo_Value(initItem, "D_POSITION")
    local initTrack = r.GetMediaItem_Track(initItem)
    local initTrackNum = r.GetMediaTrackInfo_Value(initTrack, "IP_TRACKNUMBER") - 1
    for i = 0, itemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local take = r.GetActiveTake(item)
        if take then
            local name = r.GetTakeName(take)
            name = NameFix(name) or name
            if itemNames[name] then
                table.insert(itemNames[name], item)
            else
                itemNames[name] = {item}
            end
        end
    end

    for name, itemTable in Tbl.PairsByKeys(itemNames) do
        local pos = initPos
        initTrackNum = initTrackNum + 1
        r.InsertTrackAtIndex(initTrackNum, true)
        local track = r.GetTrack(0, initTrackNum)
        r.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
        for i, item in ipairs(itemTable) do
            r.MoveMediaItemToTrack(item, track)
            r.SetMediaItemPosition(item, pos, true)
            pos = pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")
        end
    end
end)