-- @noindex
-- USER CONFIG --
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local function create_folder(tracks)
    local track = tracks[1]
    local idx = track.num
    r.InsertTrackAtIndex(idx - 1, true) -- insert new track above first selected track
    Tracks().sel = false
    tracks.sel = true
    r.ReorderSelectedTracks(idx, 1) -- add tracks to folder in newly created track
    tracks.sel = false
    track.parent.sel = true
    track.parent.channels = tracks.maxchannels

    local columns = Columns(tracks.items)

    Items().sel = false
    for i, col in ipairs(columns) do
        FolderItem.Create(track.parent, col).sel = true
        col.items.sel = true
    end
    if COLLAPSE_FOLDER_TRACK_AFTER_CREATION then
        ToggleVisibility(track.parent)
    end
    r.Main_OnCommand(40914, 0) -- Track: Set first selected track as last touched track
end

function Main()
    local focus = r.GetCursorContext()
    local items = Items()
    local tracks = Tracks()
    if focus == 0 or #items == 0 then
        if #tracks == 0 then return end
        create_folder(tracks)
    else
        local item_tracks = items.tracks
        assert(#item_tracks > 0)
        if #items < #item_tracks.items then
            local idx = item_tracks[1].num > 1 and item_tracks[1].num - 1 or item_tracks[#item_tracks].num
            tracks.sel = false
            item_tracks.sel = true
            r.Main_OnCommand(40210, 0)       -- Track: Copy tracks
            r.Main_OnCommand(40006, 0)       -- Item: Remove items
            Track(idx):SetLastTouched()
            r.Main_OnCommand(42398, 0)       -- Item: Paste items/tracks
            item_tracks = Tracks()
            item_tracks.items.unselected:Delete() -- delete unselected newly copied items on new tracks
        end
        create_folder(item_tracks)
    end
    if renameFolderItems and r.CountSelectedMediaItems(0) > 0 then
        r.Main_OnCommand(r.NamedCommandLookup("_RSe8733f58b84754de32c3dd2cdd466a1ac6231322"), 0) -- rename items
    elseif renameTrack then
        r.Main_OnCommand(40696, 0)                                                               -- rename last touched track
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
