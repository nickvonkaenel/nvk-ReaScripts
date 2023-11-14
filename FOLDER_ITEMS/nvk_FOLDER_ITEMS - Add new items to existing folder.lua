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

function CreateFolderItems(columns, track)
    local name = nil
    local prevName = nil
    local folderItems = GetFolderItems(track)
    local doNum = true
    for i = 1, #columns do
        local column = columns[i]
        local s, e = column[1], column[2]
        local fixItem = nil
        for i = 1, #folderItems do
            local folderItem = folderItems[i]
            -- local prevFolderItem = folderItems[i - 1]
            local fs = folderItem[2] -- current folder item start
            -- current folder item start
            local fe = folderItem[3] -- current folder item end
            -- current folder item end
            if (s >= fs and s <= fe) or (e >= fs and e <= fe) or (e >= fe and s <= fs) then
                -- if folderItem[4] ~= "" and folderItem[4] ~= " " then
                name = folderItem[4]
                -- end
                fixItem = folderItem[1]
                doNum = folderItem[5]
                table.remove(folderItems, i)
                break
            elseif fs < s then
                if folderItem[4] ~= '' and folderItem[4] ~= ' ' then
                    name = folderItem[4] -- backup name
                    -- backup name
                end
            end
        end
        if name == '' or name == ' ' then name = nil end
        if name and name == prevName then
            numCount = numCount + 1
            local newName = name
            if doNum then newName = newName .. doNum .. string.format('%02d', numCount) end
            item, take = CreateFolderItem(track, s, e - s, newName, fixItem)
            if doIndividualMarkers then
                if useItemColors then
                    color = reaper.GetDisplayedMediaItemColor2(item, take)
                    if color == 0 then color = defaultColor end
                else
                    color = defaultColor
                end
                markers[#markers + 1] = { doRegion, s, e, newName, color }
            else
                markers[#markers][3] = e
            end
        else
            local newName = name
            if name then
                numCount = 1
                if doNum then newName = newName .. doNum .. string.format('%02d', numCount) end
                item, take = CreateFolderItem(track, s, e - s, newName, fixItem)
                prevName = name
            else
                item, take = CreateFolderItem(track, s, e - s, ' ', fixItem)
            end
            if useItemColors then
                color = reaper.GetDisplayedMediaItemColor2(item, take)
                if color == 0 then color = defaultColor end
            else
                color = defaultColor
            end
            if name then
                if doIndividualMarkers then
                    markers[#markers + 1] = { doRegion, s, e, newName, color }
                else
                    markers[#markers + 1] = { doRegion, s, e, name, color }
                end
            end
        end
        columnsItems[i][#columnsItems[i] + 1] = item
    end
    for i = 1, #folderItems do reaper.DeleteTrackMediaItem(track, folderItems[i][1]) end
end

function GetFolderItems(track) --overrides default function to do time selection
    ls, le = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if ls == le then
        ls = 0
        le = math.huge
        if itemsSelected then
            ls = items[1][2]      -- start of items
            -- start of items
            le = items[#items][3] -- end of items
            -- end of items
        end
    end
    local folderItems = {}
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        if IsFolderItem(item) then
            local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local itemEnd = itemPos + itemLen
            if (itemPos >= ls and itemPos <= le) or (itemEnd >= ls and itemEnd <= le) or (itemEnd >= le and itemPos <= ls) then
                local take = reaper.GetActiveTake(item)
                local name = reaper.GetTakeName(take)
                local name, doNum = FastNameFix(name)
                table.insert(folderItems, { item, itemPos, itemEnd, name, doNum })
            end
        end
    end
    return folderItems
end

function Main()
    reaper.Main_OnCommand(41110, 0) -- select track under mouse
    selTrack = reaper.GetSelectedTrack(0, 0)
    selTrackFolderDepth = reaper.GetMediaTrackInfo_Value(selTrack, "I_FOLDERDEPTH")
    itemCount = reaper.CountSelectedMediaItems(0)
    markers = {} --isn't used just referenced in folder item script
    if itemCount > 0 then
        items = {}
        GetValidItems(items)
        if #items == 0 then
            return
        end
        columns, columnsItems = GetColumnsTable(items)
        selTrack = reaper.GetParentTrack(reaper.GetMediaItem_Track(items[1][1])) -- get parent track of first item
        itemsSelected = true
    elseif selTrackFolderDepth == 1 then
        SelectChildrenTracks(selTrack)
        SelectItemsInSelection()
        items = {}
        GetValidItems(items)
        if #items == 0 then
            return
        end
        columns, columnsItems = GetColumnsTable(items)
    else
        SelectItemsInSelection()
        return
    end
    if selTrack then
        CreateFolderItems(columns, selTrack)
        if reaper.GetMediaTrackInfo_Value(selTrack, "I_FOLDERCOMPACT") == 2 then
            GroupColumnsItems(columnsItems)
        else
            SelectColumnsItems(columnsItems)
        end
        reaper.SetOnlyTrackSelected(selTrack)
    end
end

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
            columns = Track.GetChildrenColumns(track, { s = ls, e = le })
        else
            columns = Track.GetChildrenColumns(track)
        end
    end
    local track_folder_items = Track.GetFolderItems(track, columns)
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
