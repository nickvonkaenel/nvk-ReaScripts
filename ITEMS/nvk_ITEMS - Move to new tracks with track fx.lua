-- @noindex
-- Special thanks (for contributing code): X-Raym, ausbaxter, me2beats
-- USER CONFIG --
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
----------------------SAVE SELECTED ITEMS--------------------
function SaveSelectedItems(table)
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        table[i + 1] = reaper.GetSelectedMediaItem(0, i)
    end
end
----------------------UNSELECT ALL TRACKS--------------------
function UnselectAllTracks()
    first_track = reaper.GetTrack(0, 0)
    reaper.SetOnlyTrackSelected(first_track)
    reaper.SetTrackSelected(first_track, false)
end
------------------------SELECT TRACKS------------------------
function SelectTracksFromItems()
    -- focus = reaper.GetCursorContext()
    -- if focus == 0 then return end
    -- LOOP THROUGH SELECTED ITEMS
    selected_items_count = reaper.CountSelectedMediaItems(0)
    if selected_items_count == 0 then
        return
    end
    UnselectAllTracks()
    -- INITIALIZE loop through selected items
    -- Select tracks with selected items
    for i = 0, selected_items_count - 1 do
        -- GET ITEMS
        item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i
        -- GET ITEM PARENT TRACK AND SELECT IT
        track = reaper.GetMediaItem_Track(item)
        reaper.SetTrackSelected(track, true)
    end -- ENDLOOP through selected tracks
end
----------------DUPLICATE ITEMS WITH TRACKS-------------------
function Elem_in_tb(elem, tb)
    _found = nil
    for eit = 1, #tb do
        if tb[eit] == elem then
            _found = 1
            break
        end
    end
    if _found then
        return 1
    end
end
sel_tracks1 = {}
sel_tracks2 = {}
function SaveSelTracks(table)
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
        table[i + 1] = reaper.GetSelectedTrack(0, i)
    end
end
function RestoreSelTracks(table)
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    for _, track in ipairs(table) do
        reaper.SetTrackSelected(track, true)
    end
end
function SetLastTouchedTrack(tr)
    SaveSelTracks(sel_tracks2)
    reaper.SetOnlyTrackSelected(tr)
    reaper.Main_OnCommand(40914, 0) -- Track: Set first selected track as last touched track
    RestoreSelTracks(sel_tracks2)
end
function SaveView()
    start_time_view, end_time_view = reaper.BR_GetArrangeView(0)
end
function RestoreView()
    reaper.BR_SetArrangeView(0, start_time_view, end_time_view)
end
function DuplicateItemsWithTracks()
    local tracks = reaper.CountSelectedTracks()
    local items = reaper.CountSelectedMediaItems()
    if items == 0 then
        return
    end
    tracks_tb = {}
    items_tb = {}
    for i = 1, items do
        local item = reaper.GetSelectedMediaItem(0, i - 1)
        local tr = reaper.GetMediaItem_Track(item)
        if not Elem_in_tb(tr, tracks_tb) then
            tracks_tb[#tracks_tb + 1] = tr
        end -- create table of tracks with selected items
        items_tb[i] = {item, tr} -- creates array within array
    end
    if #tracks_tb == 1 then ---if only one track (makes things simpler)
        SaveSelTracks(sel_tracks1)
        local tr = tracks_tb[1]
        reaper.SetOnlyTrackSelected(tr)
        reaper.Main_OnCommand(40062, 0) -- Track: Duplicate tracks
        for i = #items_tb, 1, -1 do
            local it = items_tb[i][1] -- multidimensional array (gets first item which is item from items_tb)
            -- multidimensional array (gets first item which is item from items_tb)
            reaper.DeleteTrackMediaItem(tr, it) -- deletes items from original track
        end
        local new_tr = reaper.GetSelectedTrack(0, 0)
        local items = reaper.CountTrackMediaItems(new_tr) -- get count of items on new track
        for i = items - 1, 0, -1 do -- iterating down from item count by -1
            local item = reaper.GetTrackMediaItem(new_tr, i)
            if not reaper.IsMediaItemSelected(item) then
                reaper.DeleteTrackMediaItem(new_tr, item)
            end -- delete unselected items from track leaving only the duplicated selected items
        end
        RestoreSelTracks(sel_tracks1)
        reaper.PreventUIRefresh(-1)
        reaper.Undo_EndBlock('Move items to new tracks (duplicate tracks)', -1)
        return
    end
    -- if more than one track--
    SaveSelTracks(sel_tracks1)
    SaveView()
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    for i = 1, #tracks_tb do
        reaper.SetTrackSelected(tracks_tb[i], 1)
    end -- select track with selected items
    local tracks = #tracks_tb
    first_track_idx = reaper.GetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "IP_TRACKNUMBER")
    last_sel = reaper.GetTrack(0, first_track_idx - 2) -- get previous track
    -- last_sel = reaper.GetSelectedTrack(0, tracks-1) --use end of tracks actually
    if first_track_idx == 1 then
        last_sel = reaper.GetSelectedTrack(0, tracks - 1)
    end -- set last selected track to the last one (can make change here)
    SetLastTouchedTrack(last_sel) -- this tells next function where to paste
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_COPYSNDRCV1'), 0) -- SWS/S&M: Copy selected tracks (with routing)
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_TRACKS'), 0) -- SWS/BR: Focus tracks
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_PASTSNDRCV1'), 0) -- SWS/S&M: Paste tracks (with routing) or items
    for i = #items_tb, 1, -1 do
        local it, tr = items_tb[i][1],
            items_tb[i][2] -- read first and second values from table within table and assign them
            -- read first and second values from table within table and assign them
        reaper.DeleteTrackMediaItem(tr, it) -- delete from old track
    end
    for j = 0, reaper.CountSelectedTracks() - 1 do -- delete other items from new track
        local new_tr = reaper.GetSelectedTrack(0, j)
        local items = reaper.CountTrackMediaItems(new_tr)
        for i = items - 1, 0, -1 do
            local item = reaper.GetTrackMediaItem(new_tr, i)
            if not reaper.IsMediaItemSelected(item) then
                reaper.DeleteTrackMediaItem(new_tr, item)
            end
        end
    end
    RestoreSelTracks(sel_tracks1)
    RestoreView()
end
-----------------------------CREATE BLANK ITEMS IN PARENT TRACK FROM SELECTED ITEM COLUMNS-------------------------
--------------------------------------Class Definitions-----------------------------------------------------
local Item = {}
Item.__index = Item
setmetatable(Item, {
    __call = function(cls, ...)
        return cls.New(...)
    end
})
function Item.New(item, i_start, i_end, m_state) -- stores reaper item, start and end values
    local self = setmetatable({}, Item)
    self.item = item
    self.s = i_start
    self.e = i_end
    self.m_state = m_state
    return self
end
--------------------------------------------Script---------------------------------------------------------
function Initialize()
    first_item = reaper.GetSelectedMediaItem(0, 0)
    first_take = reaper.GetActiveTake(first_item)
    -- if first_take ~= nil then retval, first_name = reaper.GetSetMediaItemTakeInfo_String(first_take, "P_NAME", "", 0) end
    first_item_track = reaper.GetMediaItem_Track(first_item)
    parent_track = reaper.GetParentTrack(first_item_track)
    region_track = reaper.GetTrack(0, 1)
    media_items = {} -- sorted selected media item list
    item_columns = {}
    track_count = reaper.CountTracks(0) - 1
    media_tracks = {}
    parent_tk_check = {} -- check for "f" mode
end
function CreateItem(track, position, length)
    local item = reaper.AddMediaItemToTrack(track)
    reaper.SetMediaItemSelected(item, 1)
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
    reaper.AddTakeToMediaItem(item)
    take = reaper.GetActiveTake(item)
    -- reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", first_name, 1)
    return item
end
function GetItemPosition(item)
    local s = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local e = s + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    return s, e
end
function InsertTrackIntoTable(t, this_track, check)
    local track_found = false
    for i, track in ipairs(t) do -- check if trying to add repeated track
        if this_track == track[1] then
            track_found = true
            break
        end
    end
    if track_found == false then
        local track_index = reaper.GetMediaTrackInfo_Value(this_track, "IP_TRACKNUMBER") - 1
        table.insert(t, {this_track, track_index})
    end
end
function InsertIntoTable(t, this_elem)
    local elem_found = false
    for i, elem in ipairs(t) do -- check if trying to add repeated track
        if this_elem == elem then
            elem_found = true
            break
        end
    end
    if elem_found == false then
        table.insert(t, this_elem)
    end
end
function GetSelectedMediaItemsAndTracks()
    all_muted = true
    in_place_bad = false
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local s, e = GetItemPosition(item)
        local m = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
        if m == 0 then
            all_muted = false
        end
        table.insert(media_items, Item(item, s, e, m))
        local track = reaper.GetMediaItem_Track(item)
        local p_track = tostring(reaper.GetParentTrack(track))
        InsertIntoTable(parent_tk_check, p_track)
        InsertTrackIntoTable(media_tracks, track)
    end
    if #parent_tk_check > 1 then -- checks if in-place is possible
        in_place_bad = true
    end
    table.sort(media_items, function(a, b)
        return a.s < b.s
    end)
end
function RestoreOriginalItemSelection()
    for i, item in ipairs(selectedMediaItems) do
        reaper.SetMediaItemInfo_Value(item[1], "B_UISEL", 1)
    end
end
------------------------MAIN----------------------------
function Main()
    focus = reaper.GetCursorContext()
    if focus == 0 then
        reaper.Main_OnCommand(40421, 0) -- select all items on track
        return
    end
    item_count = reaper.CountSelectedMediaItems(0)
    if item_count > 0 then
        init_sel_items = {}
        SaveSelectedItems(init_sel_items)
        SelectTracksFromItems()
        reaper.Main_OnCommand(40421, 0) -- select all items on track
        if item_count < reaper.CountSelectedMediaItems(0) then -- if other items on track besides selected 
            reaper.Main_OnCommand(40289, 0) -- unselect all items
            for i, item in ipairs(init_sel_items) do
                reaper.SetMediaItemSelected(item, 1) -- select orignal items
            end
            DuplicateItemsWithTracks()
        end
        SelectTracksFromItems()
    end
end
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
