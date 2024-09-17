-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
scr = {}
SEP = package.config:sub(1, 1)
local info = debug.getinfo(1, 'S')
scr.path, scr.name = info.source:match [[^@?(.*[\/])(.*)%.lua$]]
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = scr.path .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    tracks = SaveSelectedTracks()
    for i, track in ipairs(tracks) do
        if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 then DeselectChildrenTracks(track) end
        if reaper.GetMediaTrackInfo_Value(track, 'I_TCPH') < 5 then reaper.SetTrackSelected(track, false) end
    end
    newTracks = SaveSelectedTracks()
    trackCount = reaper.CountTracks(0)
    for i, track in ipairs(newTracks) do
        idx = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER') - 1
        if idx == 0 then return end
        reaper.SetOnlyTrackSelected(track)
        for i = idx - 1, 0, -1 do
            prevTrack = reaper.GetTrack(0, i)
            if reaper.GetMediaTrackInfo_Value(prevTrack, 'I_TCPH') >= 5 then
                prevTrackIdx = i
                break
            end
        end
        trackDepth = reaper.GetTrackDepth(track)
        prevDepth = reaper.GetTrackDepth(prevTrack)
        prevFolderDepth = reaper.GetMediaTrackInfo_Value(prevTrack, 'I_FOLDERDEPTH')
        prevCompact = reaper.GetMediaTrackInfo_Value(prevTrack, 'I_FOLDERCOMPACT')
        parent = reaper.GetParentTrack(track)
        if prevFolderDepth < 0 then
            reaper.ReorderSelectedTracks(idx, 2)
        elseif prevFolderDepth == 1 and prevTrack ~= parent and prevCompact == 2 and trackDepth ~= prevDepth then
            reaper.ReorderSelectedTracks(prevTrackIdx, 0)
            reaper.SetOnlyTrackSelected(prevTrack)
            reaper.ReorderSelectedTracks(prevTrackIdx, 0)
        else
            reaper.ReorderSelectedTracks(prevTrackIdx, 0)
        end
        if i == 1 then
            if idx < trackCount - 1 then
                reaper.Main_OnCommand(40285, 0)
                reaper.Main_OnCommand(40286, 0)
            else
                reaper.Main_OnCommand(40286, 0)
                reaper.Main_OnCommand(40285, 0)
            end
        end
    end
    RestoreSelectedTracks(tracks)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
