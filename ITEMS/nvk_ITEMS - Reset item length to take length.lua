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
    local xStart, xEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local pos = reaper.GetCursorPosition()
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local take = reaper.GetActiveTake(item)
        local src = reaper.GetMediaItemTake_Source(take)
        local srcLen = reaper.GetMediaSourceLength(src)
        reaper.SetMediaItemLength(item, srcLen, false)
        reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", 0)
    end
    reaper.SetEditCurPos(pos, false, false)
    reaper.GetSet_ArrangeView2(0, true, 0, 0, xStart, xEnd)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)