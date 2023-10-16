-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
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
reaper.Undo_EndBlock(scrName, -1)