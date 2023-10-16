-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    items = SaveSelectedItems()

    if #items > 0 then
        reaper.Main_OnCommand(40289, 0) -- unselect all items
        -- reaper.Main_OnCommand(42387, 0) --delete all take markers
    end

    num = 0

    for i, item in ipairs(items) do
        track = reaper.GetMediaItem_Track(item)
        take = reaper.GetActiveTake(item)
        if take then
            if track == initTrack then
                
                playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
                source = reaper.GetMediaItemTake_Source(take)
                sourceName = reaper.GetMediaSourceFileName(source, "")
                if sourceName == initSourceName then
                    num = num + 1

                    if num > 1 then
                        offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                        snapoffset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
                        reaper.SetTakeMarker(firstItemTake, -1, tostring(num), offset + snapoffset * playrate)
                    end
                    if i > 1 then
                        track = reaper.GetMediaItem_Track(item)
                        reaper.DeleteTrackMediaItem(track, item)
                    end
                else
                    reaper.SetMediaItemSelected(item, true)
                end
            else
                if num > 1 then
                    reaper.SetTakeMarker(firstItemTake, -1, "1", firstItemOffset + firstItemSnapoffset * firstItemPlayrate)
                end
                initTrack = track
                firstItem = item
                firstItemTake = reaper.GetActiveTake(firstItem)
                firstItemPlayrate = reaper.GetMediaItemTakeInfo_Value(firstItemTake, "D_PLAYRATE")
                firstItemOffset = reaper.GetMediaItemTakeInfo_Value(firstItemTake, "D_STARTOFFS")
                firstItemSnapoffset = reaper.GetMediaItemInfo_Value(firstItem, "D_SNAPOFFSET")
                initSource = reaper.GetMediaItemTake_Source(firstItemTake)
                initSourceName = reaper.GetMediaSourceFileName(initSource, "")
                reaper.SetMediaItemSelected(firstItem, true)
                num = 1
            end
        end
    end
    if num > 1 then
        reaper.SetTakeMarker(firstItemTake, -1, "1", firstItemOffset + firstItemSnapoffset * firstItemPlayrate)
    end
    -- reaper.Main_OnCommand(40644, 0) --Item: Implode items across tracks into items on one track
    reaper.Main_OnCommand(40543, 0) -- Take: Implode items on same track into takes

end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
