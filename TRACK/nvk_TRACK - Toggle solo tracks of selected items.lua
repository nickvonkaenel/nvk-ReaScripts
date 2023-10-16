-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
scr = {}
sep = package.config:sub(1, 1)
local info = debug.getinfo(1,'S')
scr.path, scr.name = info.source:match[[^@?(.*[\/])(.*)%.lua$]]
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = scr.path .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    tracks = SaveSelectedTracks()
    focus = reaper.GetCursorContext()
    if focus == 0 then
        reaper.Main_OnCommand(7, 0)
        return
    end
    solo = true
    for i = 0, reaper.CountTracks(0) - 1 do
        if not solo then
            return
        end
        track = reaper.GetTrack(0, i)
        if reaper.GetMediaTrackInfo_Value(track, "I_SOLO") > 0 then
            reaper.Main_OnCommand(40340, 0) -- unsolo all
            solo = false
            return
        end
    end
    itemCount = reaper.CountSelectedMediaItems(0)
    if solo and itemCount > 0 then
        reaper.Main_OnCommand(40297, 0) -- unselect all tracks
        for i = 0, itemCount - 1 do
            item = reaper.GetSelectedMediaItem(0, i)
            track = reaper.GetMediaItemTrack(item)
            reaper.SetTrackSelected(track, true)
        end
    end
    reaper.Main_OnCommand(7, 0) -- toggle solo selected tracks
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    for i, track in ipairs(tracks) do
        reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
