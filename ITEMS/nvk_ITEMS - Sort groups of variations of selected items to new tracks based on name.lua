-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
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
    local i = 0 -- iterator variable
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

function Main()
    local itemNames = {}
    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount == 0 then
        return
    end
    local initItem = reaper.GetSelectedMediaItem(0, 0)
    local initPos = reaper.GetMediaItemInfo_Value(initItem, "D_POSITION")
    local initTrack = reaper.GetMediaItem_Track(initItem)
    local initTrackNum = reaper.GetMediaTrackInfo_Value(initTrack, "IP_TRACKNUMBER") - 1
    for i = 0, itemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        if take then
            local name = NameFix(reaper.GetTakeName(take))
            if itemNames[name] then
                table.insert(itemNames[name], item)
            else
                itemNames[name] = {item}
            end
        end
    end

    for name, itemTable in PairsByKeys(itemNames) do
        local pos = initPos
        initTrackNum = initTrackNum + 1
        reaper.InsertTrackAtIndex(initTrackNum, true)
        local track = reaper.GetTrack(0, initTrackNum)
        for i, item in ipairs(itemTable) do
            reaper.MoveMediaItemToTrack(item, track)
            reaper.SetMediaItemPosition(item, pos, true)
            pos = pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
