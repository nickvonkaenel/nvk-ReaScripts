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
    local t = {}
    for i = 0, reaper.CountSelectedMediaItems() - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if reaper.GetMediaItemInfo_Value(item, 'B_MUTE') == 1 then
            t[#t+1] = item
        end
    end
    for i = 1, #t do
        local item = t[i]
        reaper.DeleteTrackMediaItem( reaper.GetMediaItem_Track(item), item )
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
