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
    local tracks = SaveSelectedTracks()
    local focus = r.GetCursorContext()
    if focus == 0 then
        r.Main_OnCommand(7, 0)
        return
    end
    local solo = true
    for i = 0, r.CountTracks(0) - 1 do
        if not solo then
            return
        end
        local track = r.GetTrack(0, i)
        if r.GetMediaTrackInfo_Value(track, "I_SOLO") > 0 then
            r.Main_OnCommand(40340, 0) -- unsolo all
            solo = false
            return
        end
    end
    local itemCount = r.CountSelectedMediaItems(0)
    if solo and itemCount > 0 then
        r.Main_OnCommand(40297, 0) -- unselect all tracks
        for i = 0, itemCount - 1 do
            local item = r.GetSelectedMediaItem(0, i)
            local track = r.GetMediaItemTrack(item)
            r.SetTrackSelected(track, true)
        end
    end
    r.Main_OnCommand(7, 0) -- toggle solo selected tracks
    r.Main_OnCommand(40297, 0) -- unselect all tracks
    for i, track in ipairs(tracks) do
        r.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
    end
end


r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)