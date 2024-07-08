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
function NameFix(name)
    if not name then return "" end
    name = string.match(name, "(.+)%..+$") or name
    return string.match(name, "(.+)[_ -]+[0-9]+[0-9]") or name
end

function PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0             -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

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
            local name = NameFix(r.GetTakeName(take))
            if itemNames[name] then
                table.insert(itemNames[name], item)
            else
                itemNames[name] = { item }
            end
        end
    end

    for name, itemTable in PairsByKeys(itemNames) do
        local pos = initPos
        initTrackNum = initTrackNum + 1
        r.InsertTrackAtIndex(initTrackNum, true)
        local track = r.GetTrack(0, initTrackNum)
        for i, item in ipairs(itemTable) do
            r.MoveMediaItemToTrack(item, track)
            r.SetMediaItemPosition(item, pos, true)
            pos = pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")
        end
    end
end)
