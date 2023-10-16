-- @noindex
-- Select items and run script to copy their positions to use with paste item positions script.
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function db2vol(x)
    return tonumber(math.exp((x) * (math.log(10) / 20)))
end

function vol2db(vol)
    return math.log(vol, 10) * 20
end

function HalveItemVolume(item)
    local volume = reaper.GetMediaItemInfo_Value(item, "D_VOL")
    local take = reaper.GetActiveTake(item)
    if take then
        local takeVol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
        volume = db2vol((vol2db(volume) + vol2db(takeVol))/2)
    end
    reaper.SetMediaItemInfo_Value(item, "D_VOL", volume)
end

function Main()
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        HalveItemVolume(item)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
