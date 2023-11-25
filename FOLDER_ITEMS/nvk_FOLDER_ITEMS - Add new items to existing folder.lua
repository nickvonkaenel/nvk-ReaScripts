-- @noindex
-- Select parent track and run script. It will add blank items matching contiguous items on the children tracks within time selection
-- legacy script, use nvk_FOLDER_ITEMS.lua or nvk_FOLDER_ITEMS - Update (manual).lua instead ideally for full features
-- USER CONFIG --
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
-- if not reaper.HasExtState(scr.name, "mm") then
--     reaper.SetExtState(scr.name, "mm", "true", true)
--     is_new_value, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
--     actionID = reaper.ReverseNamedCommandLookup(cmdID)
--     actionID = "_" .. actionID
--     if actionID ~= reaper.GetMouseModifier("MM_CTX_TRACK_DBLCLK", 0, "") then
--         if reaper.ShowMessageBox(
--             "This script will change the double click mouse modifiers for tracks\n\nIf you would prefer to set up mouse modifiers manually, choose \'cancel\', then edit the script and change mouse_modifiers to \'false\'",
--             "Warning", 1) ~= 1 then
--             return
--         end
--         reaper.ShowMessageBox("Double click on a black space in the parent track to add folder items", "Instructions", 0)
--         reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 0, actionID)
--         return
--     end
-- end

function Main()
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
            columns = track:ChildrenColumns({ s = ls, e = le })
        else
            columns = track:ChildrenColumns()
        end
    end
    local track_folder_items = track:FolderItems(columns)
    local name, name_id -- name id not used since we aren't worry about markers
    for _, col in ipairs(columns) do
        local folder_item = FolderItems.ColumnOverlap(track_folder_items, col)
        if folder_item then
            name, name_id = FolderItem.NameFormat(folder_item.name, names)
            FolderItem.Create(track, col, disableAutoName and folder_item.name or name, folder_item)
        else
            name, name_id = FolderItem.NameFormat(disableAutoName and ' ' or name, names)
            folder_item = FolderItem.Create(track, col, name)
        end
    end
    for _, folder_item in ipairs(track_folder_items) do
        r.DeleteTrackMediaItem(track.track, folder_item.item)
    end
    -- need to group items if collapsed track
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
