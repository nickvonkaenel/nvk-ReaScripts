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
    itemsToDelete = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        color = reaper.GetDisplayedMediaItemColor(item)
        if color == 0 then
            table.insert(itemsToDelete, item)
        end
    end

    for i, item in ipairs(itemsToDelete) do
        track = reaper.GetMediaItem_Track(item)
        reaper.DeleteTrackMediaItem(track, item)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)