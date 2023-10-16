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
    compactStates = {}
    trackCount = reaper.CountTracks(0) - 1

    for i = 0, trackCount - 1 do
        track = reaper.GetTrack(0 ,i)
        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
            table.insert(compactStates, reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT"))
        end
    end

    s = 0
    for i, v in ipairs(compactStates) do
        s = s + v
    end

    state = math.floor((s/#compactStates)+0.5)

    newState = (state+1)%3

    for i = 0, trackCount - 1 do
        track = reaper.GetTrack(0 ,i)
        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
            reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", newState)
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)