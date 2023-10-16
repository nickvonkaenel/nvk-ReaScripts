-- @noindex
-- USER CONFIG --
centerChannel = 3
centerChannelDB = -3
lfeChannel = 4
lfeChannelDB = -3
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    retval, retvals_csv = r.GetUserInputs("5.1 to Quad", 4, "Center Channel,Center dB,LFE Channel,LFE dB",
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
        take = r.GetActiveTake(initItem)
        if take then
            name = r.GetTakeName(take)
            source = r.GetMediaItemTake_Source(take)
            channelCount = r.GetMediaSourceNumChannels(source)
            initTrack = r.GetMediaItem_Track(initItem)
            r.InsertTrackAtIndex(0, false)
            renderTrack = r.GetTrack(0, 0)
            r.Main_OnCommand(40769, 0) -- unselect everything (have to select all tracks first else some envelope tracks can be selected)
            r.SetMediaItemSelected(initItem, true)
            r.Main_OnCommand(40290, 0) -- time selection to items
            r.Main_OnCommand(41173, 0) -- cursor to start of items
            r.Main_OnCommand(40698, 0) -- copy items
            skipCount = 0
            for i = 1, channelCount do
                r.InsertTrackAtIndex(i, false)
                local track = r.GetTrack(0, i)
                r.SetTrackSelected(track, true)
                SetLastTouchedTrack(track)
                r.Main_OnCommand(42398, 0) -- paste items/tracks
                item = r.GetSelectedMediaItem(0, 0)
                take = r.GetActiveTake(item)
                r.SetMediaItemTakeInfo_Value(take, "I_CHANMODE", i + 2)
                if tostring(i) == centerChannel then
                    r.SetMediaTrackInfo_Value(track, "D_VOL", 2 ^ (centerChannelDB / 6))
                    skipCount = skipCount + 1
                elseif tostring(i) == lfeChannel then
                    r.SetMediaTrackInfo_Value(track, "D_VOL", 2 ^ (lfeChannelDB / 6))
                    skipCount = skipCount + 1
                else
                    r.SetMediaTrackInfo_Value(track, "D_PAN", -1)
                    r.SetMediaTrackInfo_Value(track, "C_MAINSEND_OFFS", i - 1 - skipCount)
                end
            end
            r.ReorderSelectedTracks(1, 1)
            r.SetOnlyTrackSelected(renderTrack)
            r.SetMediaTrackInfo_Value(renderTrack, "I_NCHAN", 4)
            r.Main_OnCommand(41720, 0) -- render selected area of tracks to multichannel stem tracks (and mute originals)
            track = r.GetSelectedTrack(0, 0)
            renderItem = r.GetTrackMediaItem(track, 0)
            take = r.GetActiveTake(renderItem)
            r.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
            r.Main_OnCommand(40769, 0) -- unselect everything (have to select all tracks first else some envelope tracks can be selected)
            r.SetMediaItemSelected(renderItem, true)
            r.Main_OnCommand(40698, 0) -- copy items
            for i = 0, channelCount + 1 do
                track = r.GetTrack(0, 0)
                r.DeleteTrack(track)
            end
            r.SetMediaItemSelected(initItem, true)
            r.Main_OnCommand(40603, 0) -- paste as takes in item
        end
    end
    r.Main_OnCommand(40020, 0) -- remove time selection
    RestoreSelectedItems(items)
    r.Main_OnCommand(41173, 0) -- cursor to start of items
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)

