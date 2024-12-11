-- @noindex
-- Select parent track and run script. It will add blank items matching contiguous items on the children tracks within time selection
-- legacy script, use nvk_FOLDER_ITEMS.lua or nvk_FOLDER_ITEMS - Update (manual).lua instead ideally for full features
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    r.Main_OnCommand(41110, 0) -- select track under mouse
    local names = {}
    local items = Items.Unmuted()
    local track, columns
    if #items > 0 then
        columns = Columns(items)
        if items[1].track.isparent then
            track = items[1].track
        elseif items[1].track.parent then
            track = items[1].track.parent
        else
            return
        end
    else
        track = Track(r.GetSelectedTrack(0, 0))
        if not track or not track.isparent then return end
        local ls, le = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
        if ls ~= le then
            columns = track:ChildrenColumns { s = ls, e = le }
        else
            columns = track:ChildrenColumns()
        end
    end
    local track_folder_items = track:FolderItems(columns)
    local name -- name id not used since we aren't worry about markers
    for _, col in ipairs(columns) do
        local folder_item = track_folder_items:ColumnOverlap(col)
        if folder_item then
            name = FolderItem.NameFormat(folder_item.name, names)
            FolderItem.Create(track, col, FOLDER_ITEMS_DISABLE_AUTO_NAMING and folder_item.name or name, folder_item)
        else
            name = FolderItem.NameFormat(FOLDER_ITEMS_DISABLE_AUTO_NAMING and ' ' or name, names)
            folder_item = FolderItem.Create(track, col, name)
        end
    end
    for _, folder_item in ipairs(track_folder_items) do
        r.DeleteTrackMediaItem(track.track, folder_item.item)
    end
    -- need to group items if collapsed track
end)
