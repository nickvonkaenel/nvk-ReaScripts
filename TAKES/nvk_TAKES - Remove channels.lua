-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
function IsChannelToRemove(num)
    for i = 1, #inputTable do
        if tostring(num) == inputTable[i] then
            return true
        end
    end
    return false
end

function Main()
    retval, retvals_csv = reaper.GetUserInputs("Remove Channels", 1, "Channels (comma-separated)", "0")
    if retval then
        inputTable = {}
        for input in string.gmatch(retvals_csv, '([^,]+)') do
            table.insert(inputTable, input)
        end
    else
        return
    end
    items = SaveSelectedItems()
    for i, initItem in ipairs(items) do
        initTake = reaper.GetActiveTake(initItem)
        if initTake then
            initPlayrate = reaper.GetMediaItemTakeInfo_Value(initTake, "D_PLAYRATE")
            CopyTakeMarkers(initTake)
            initOffset = reaper.GetMediaItemTakeInfo_Value(initTake, "D_STARTOFFS")
            initPitch = reaper.GetMediaItemTakeInfo_Value(initTake, "D_PITCH")
            preservePitch = reaper.GetMediaItemTakeInfo_Value(initTake, "B_PPITCH")
            reaper.SetMediaItemTakeInfo_Value(initTake, "D_PITCH", 0)
            reaper.SetMediaItemTakeInfo_Value(initTake, "D_PLAYRATE", 1)
            reaper.SetMediaItemTakeInfo_Value(initTake, "D_STARTOFFS", 0)
            snapOffset = reaper.GetMediaItemInfo_Value(initItem, "D_SNAPOFFSET")
            reaper.SetMediaItemInfo_Value(initItem, "D_SNAPOFFSET", 0)
            initItemLen = reaper.GetMediaItemInfo_Value(initItem, "D_LENGTH")
            name = reaper.GetTakeName(initTake)
            source = reaper.GetMediaItemTake_Source(initTake)
            sourceLen = reaper.GetMediaSourceLength(source)
            reaper.SetMediaItemInfo_Value(initItem, "D_LENGTH", sourceLen)
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
                if IsChannelToRemove(i) then
                    skipCount = skipCount + 1
                else
                    reaper.InsertTrackAtIndex(i - skipCount, false)
                    local track = reaper.GetTrack(0, i - skipCount)
                    reaper.SetTrackSelected(track, true)
                    SetLastTouchedTrack(track)
                    reaper.SetMediaTrackInfo_Value(track, "D_PAN", -1)
                    reaper.SetMediaTrackInfo_Value(track, "C_MAINSEND_OFFS", i - 1 - skipCount)
                    reaper.Main_OnCommand(42398, 0) -- paste items/tracks
                    item = reaper.GetSelectedMediaItem(0, 0)
                    take = reaper.GetActiveTake(item)
                    reaper.SetMediaItemTakeInfo_Value(take, "I_CHANMODE", i + 2)
                end
            end
            reaper.ReorderSelectedTracks(1, 1)
            reaper.SetOnlyTrackSelected(renderTrack)
            if (channelCount - #inputTable) % 2 == 0 then
                trackChannels = channelCount - skipCount
            else
                trackChannels = channelCount - skipCount + 1
            end
            reaper.SetMediaTrackInfo_Value(renderTrack, "I_NCHAN", trackChannels)
            if channelCount - skipCount == 1 then
                reaper.Main_OnCommand(41721, 0) -- render selected area of tracks to mono stem tracks (and mute originals)
            else
                reaper.Main_OnCommand(41720, 0) -- render selected area of tracks to multichannel stem tracks (and mute originals)
            end
            track = reaper.GetSelectedTrack(0, 0)
            renderItem = reaper.GetTrackMediaItem(track, 0)
            take = reaper.GetActiveTake(renderItem)
            reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
            reaper.Main_OnCommand(40769, 0) -- unselect everything (have to select all tracks first else some envelope tracks can be selected)
            reaper.SetMediaItemSelected(renderItem, true)
            reaper.Main_OnCommand(40698, 0) -- copy items
            for i = 0, channelCount - skipCount + 1 do
                track = reaper.GetTrack(0, 0)
                reaper.DeleteTrack(track)
            end
            reaper.SetMediaItemSelected(initItem, true)
            reaper.Main_OnCommand(40603, 0) -- paste as takes in item
            reaper.SetMediaItemTakeInfo_Value(initTake, "D_PLAYRATE", initPlayrate)
            reaper.SetMediaItemTakeInfo_Value(initTake, "D_STARTOFFS", initOffset)
            reaper.SetMediaItemInfo_Value(initItem, "D_LENGTH", initItemLen)
            reaper.SetMediaItemInfo_Value(initItem, "D_SNAPOFFSET", snapOffset)
            reaper.SetMediaItemTakeInfo_Value(initTake, "D_PITCH", initPitch)
            reaper.SetMediaItemTakeInfo_Value(initTake, "B_PPITCH", preservePitch)
            take = reaper.GetActiveTake(initItem)
            reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", initPlayrate)
            reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", initOffset)
            reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", initPitch)
            reaper.SetMediaItemTakeInfo_Value(take, "B_PPITCH", preservePitch)
            PasteTakeMarkers(take)
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

