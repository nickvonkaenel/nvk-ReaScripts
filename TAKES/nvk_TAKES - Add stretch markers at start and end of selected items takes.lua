-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function GetItemPosition(item)
    local s = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local e = s + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    return s, e
end

function Main()
    local items = SaveSelectedItems()
    reaper.Main_OnCommand(40796, 0) -- Clear take preserve pitch
    for i, item in ipairs(items) do
        local take = reaper.GetActiveTake(item)
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        for i = reaper.GetTakeNumStretchMarkers(take) - 1, 0, -1 do
            reaper.DeleteTakeStretchMarkers(take, i)
        end
        reaper.SetTakeStretchMarker(take, -1, 0)
        reaper.SetTakeStretchMarker(take, -1, itemLength*playrate)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
