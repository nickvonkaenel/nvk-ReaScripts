-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    items = SaveSelectedItems()

    if #items > 0 then
        r.Main_OnCommand(40289, 0) -- unselect all items
        -- reaper.Main_OnCommand(42387, 0) --delete all take markers
    end

    num = 0

    for i, item in ipairs(items) do
        track = r.GetMediaItem_Track(item)
        take = r.GetActiveTake(item)
        if take then
            if track == initTrack then
                
                playrate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
                source = r.GetMediaItemTake_Source(take)
                sourceName = r.GetMediaSourceFileName(source, "")
                if sourceName == initSourceName then
                    num = num + 1

                    if num > 1 then
                        offset = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                        snapoffset = r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
                        r.SetTakeMarker(firstItemTake, -1, tostring(num), offset + snapoffset * playrate)
                    end
                    if i > 1 then
                        track = r.GetMediaItem_Track(item)
                        r.DeleteTrackMediaItem(track, item)
                    end
                else
                    r.SetMediaItemSelected(item, true)
                end
            else
                if num > 1 then
                    r.SetTakeMarker(firstItemTake, -1, "1", firstItemOffset + firstItemSnapoffset * firstItemPlayrate)
                end
                initTrack = track
                firstItem = item
                firstItemTake = r.GetActiveTake(firstItem)
                firstItemPlayrate = r.GetMediaItemTakeInfo_Value(firstItemTake, "D_PLAYRATE")
                firstItemOffset = r.GetMediaItemTakeInfo_Value(firstItemTake, "D_STARTOFFS")
                firstItemSnapoffset = r.GetMediaItemInfo_Value(firstItem, "D_SNAPOFFSET")
                initSource = r.GetMediaItemTake_Source(firstItemTake)
                initSourceName = r.GetMediaSourceFileName(initSource, "")
                r.SetMediaItemSelected(firstItem, true)
                num = 1
            end
        end
    end
    if num > 1 then
        r.SetTakeMarker(firstItemTake, -1, "1", firstItemOffset + firstItemSnapoffset * firstItemPlayrate)
    end
    -- reaper.Main_OnCommand(40644, 0) --Item: Implode items across tracks into items on one track
    r.Main_OnCommand(40543, 0) -- Take: Implode items on same track into takes

end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
