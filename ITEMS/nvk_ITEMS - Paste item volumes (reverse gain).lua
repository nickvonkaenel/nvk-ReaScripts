-- @noindex
-- pastes item volumes from clipboard but gain is reversed from 0 db so +6db becomes -6db and -6db becomes +6db
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

function ReverseGain(vol)
    return db2vol(-vol2db(vol))
end

function Main()
    section, key = "nvk_copyPaste", "itemVolumes"
    itemVolumesString = reaper.GetExtState(section, key)
    if itemVolumesString then
        itemCount = reaper.CountSelectedMediaItems(0)
        if itemCount > 0 then
            items = {}
            for i = 0, itemCount - 1 do
                item = reaper.GetSelectedMediaItem(0, i)
                items[i + 1] = item
            end
            i = 1
            for vol in itemVolumesString:gmatch "(.-)," do
                if items[i] then
                    reaper.SetMediaItemInfo_Value(items[i], "D_VOL", ReverseGain(vol))
                    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(items[i]), "D_VOL", 1)
                end
                i = i + 1
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
