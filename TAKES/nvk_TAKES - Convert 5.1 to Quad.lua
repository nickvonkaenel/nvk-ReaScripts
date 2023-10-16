-- @noindex
-- USER CONFIG --
centerChannel = 3
centerChannelDB = -3
lfeChannel = 4
lfeChannelDB = -3
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function Main()
    retval, retvals_csv = reaper.GetUserInputs("5.1 to Quad", 4, "Center Channel,Center dB,LFE Channel,LFE dB",
                              centerChannel .. "," .. centerChannelDB .. "," .. lfeChannel .. "," .. lfeChannelDB)
    if retval then
        centerChannel, centerChannelDB, lfeChannel, lfeChannelDB =
            string.match(retvals_csv, "([^,]+),([^,]+),([^,]+),([^,]+)")
        centerChannelDB = tonumber(centerChannelDB)
        lfeChannelDB = tonumber(lfeChannelDB)
    else
        return
    end
    items = SaveSelectedItems()
    for i, initItem in ipairs(items) do
        take = reaper.GetActiveTake(initItem)
        if take then
            name = reaper.GetTakeName(take)
            source = reaper.GetMediaItemTake_Source(take)
            channelCount = reaper.GetMediaSourceNumChannels(source)
            initTrack = reaper.GetMediaItem_Track(initItem)
            reaper.InsertTrackAtIndex(0, false)
            renderTrack = reaper.GetTrack(0, 0)
            reaper.Main_OnCommand(40769, 0) -- unselect everything (have to select all tracks first else some envelope tracks can be selected)
            reaper.SetMediaItemSelected(initItem, true)
            reaper.Main_OnCommand(40290, 0) -- time selection to items
            reaper.Main_OnCommand(41173, 0) -- cursor to start of items
            reaper.Main_OnCommand(40698, 0) -- copy items
            skipCount = 0
            for i = 1, channelCount do
                reaper.InsertTrackAtIndex(i, false)
                local track = reaper.GetTrack(0, i)
                reaper.SetTrackSelected(track, true)
                SetLastTouchedTrack(track)
                reaper.Main_OnCommand(42398, 0) -- paste items/tracks
                item = reaper.GetSelectedMediaItem(0, 0)
                take = reaper.GetActiveTake(item)
                reaper.SetMediaItemTakeInfo_Value(take, "I_CHANMODE", i + 2)
                if tostring(i) == centerChannel then
                    reaper.SetMediaTrackInfo_Value(track, "D_VOL", 2 ^ (centerChannelDB / 6))
                    skipCount = skipCount + 1
                elseif tostring(i) == lfeChannel then
                    reaper.SetMediaTrackInfo_Value(track, "D_VOL", 2 ^ (lfeChannelDB / 6))
                    skipCount = skipCount + 1
                else
                    reaper.SetMediaTrackInfo_Value(track, "D_PAN", -1)
                    reaper.SetMediaTrackInfo_Value(track, "C_MAINSEND_OFFS", i - 1 - skipCount)
                end
            end
            reaper.ReorderSelectedTracks(1, 1)
            reaper.SetOnlyTrackSelected(renderTrack)
            reaper.SetMediaTrackInfo_Value(renderTrack, "I_NCHAN", 4)
            reaper.Main_OnCommand(41720, 0) -- render selected area of tracks to multichannel stem tracks (and mute originals)
            track = reaper.GetSelectedTrack(0, 0)
            renderItem = reaper.GetTrackMediaItem(track, 0)
            take = reaper.GetActiveTake(renderItem)
            reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
            reaper.Main_OnCommand(40769, 0) -- unselect everything (have to select all tracks first else some envelope tracks can be selected)
            reaper.SetMediaItemSelected(renderItem, true)
            reaper.Main_OnCommand(40698, 0) -- copy items
            for i = 0, channelCount + 1 do
                track = reaper.GetTrack(0, 0)
                reaper.DeleteTrack(track)
            end
            reaper.SetMediaItemSelected(initItem, true)
            reaper.Main_OnCommand(40603, 0) -- paste as takes in item
        end
    end
    reaper.Main_OnCommand(40020, 0) -- remove time selection
    RestoreSelectedItems(items)
    reaper.Main_OnCommand(41173, 0) -- cursor to start of items
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)

