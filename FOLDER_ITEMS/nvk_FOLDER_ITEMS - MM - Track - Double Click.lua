-- @noindex
-- Mouse modifier: This script will be assigned to your mouse modifiers by the folder items - settings script. Not expected to be assigned to a shortcut.
-- USER CONFIG--
-- SETUP--
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT--
function Main()
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then return end
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        reaper.SetMediaItemSelected(item, true)
        if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 and IsFolderItem(item) then groupSelect(item) end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
