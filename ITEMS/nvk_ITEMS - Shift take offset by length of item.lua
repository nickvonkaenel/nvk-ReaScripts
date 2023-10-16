-- @noindex
-- USER CONFIG --
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        take = reaper.GetActiveTake(item)
        length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        takeOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
        reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", length + takeOffset)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
