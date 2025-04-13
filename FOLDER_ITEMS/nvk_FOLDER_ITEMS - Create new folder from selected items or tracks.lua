-- @noindex
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
---@param tracks Tracks
local function create_folder(tracks)
    local parent = tracks:AddToFolder()
    local items = tracks.items
    local columns = Columns(items.unmuted)
    Items.UnselectAll()
    for i, column in ipairs(columns) do
        FolderItem.Create(parent, column).sel = true
    end
    items.sel = true
    if COLLAPSE_FOLDER_TRACK_AFTER_CREATION then parent:ToggleVisibility() end
    parent:SetLastTouched()
end

local rv = run(function()
    local focus = r.GetCursorContext()
    local items = Items.Selected()
    local tracks = Tracks.Selected()
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
            r.Main_OnCommand(40210, 0) -- Track: Copy tracks
            r.Main_OnCommand(40006, 0) -- Item: Remove items
            Track(idx):SetLastTouched()
            r.Main_OnCommand(42398, 0) -- Item: Paste items/tracks
            item_tracks = Tracks.Selected()
            item_tracks.items.unselected:Delete() -- delete unselected newly copied items on new tracks
        end
        create_folder(item_tracks)
    end
    return true
end)

if rv then -- for some reason, when these are in the main function, they don't work
    if RENAME_ITEMS_AFTER_FOLDER_CREATION and r.CountSelectedMediaItems(0) > 0 then
        r.Main_OnCommand(r.NamedCommandLookup '_RSe8733f58b84754de32c3dd2cdd466a1ac6231322', 0) -- rename items
    elseif RENAME_TRACK_AFTER_NEW_FOLDER_CREATION then
        r.Main_OnCommand(40696, 0) -- rename last touched track
    end
end
