-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a, b)
    if not b then b = ".dat" end
    local c = scrPath .. "Data" .. sep .. a .. b;
    return c
end
OS = reaper.GetOS()
sep = OS:match "Win" and "\\" or "/"
scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"
loadfile(GetPath "functions")()
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local focus = reaper.GetCursorContext()
    local itemCount = reaper.CountSelectedMediaItems(0)
    if focus == 0 or itemCount <= 0 then
        SelectItemsOnSelectedTracks()
        FolderItemTrackCreate()
    else
        SelectTracksFromItems()
        if itemCount < CountSelectedTracksItems() then DuplicateItemsWithTracks() end
        FolderItemTrackCreate()
    end
end

function SelectItemsOnSelectedTracks(keepSelection)
    if not keepSelection then reaper.SelectAllMediaItems(0, false) end
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        for i = 0, reaper.CountTrackMediaItems(track) - 1 do
            local item = reaper.GetTrackMediaItem(track, i)
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

function FolderItemTrackCreate()
    local parentTrack = CreateFolderFromSelectedTracks()
    CreateFolderItemsForSelectedItemsAndCollapseAndGroup(parentTrack)
    reaper.SetOnlyTrackSelected(parentTrack)
    reaper.Main_OnCommand(40914, 0) -- Track: Set first selected track as last touched track
end

function CreateFolderItemsForSelectedItemsAndCollapseAndGroup(parentTrack)
    local items = GetItems()
    if #items == 0 then return end
    if not createTopLevelFolderItemsOnly or (createTopLevelFolderItemsOnly and reaper.GetTrackDepth(parentTrack) == 0) then
        columns, columnsItems = GetColumnsTable(items)
        for i, column in ipairs(columns) do -- create folder items
            local s, e = column[1], column[2]
            local item = CreateFolderItem(parentTrack, s, e - s, " ")
            table.insert(columnsItems[i], item)
            reaper.SetMediaItemSelected(item, true)
        end
        if collapse then -- user setting for collapse
            reaper.SetMediaTrackInfo_Value(parentTrack, "I_FOLDERCOMPACT", 2)
        end
        if reaper.GetMediaTrackInfo_Value(parentTrack, "I_FOLDERCOMPACT") == 2 then GroupColumnsItems(columnsItems) end
    end
end

function PostCreation()
    if renameFolderItems and reaper.CountSelectedMediaItems(0) > 0 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_RSe8733f58b84754de32c3dd2cdd466a1ac6231322"), 0) -- rename items
    elseif renameTrack then
        reaper.Main_OnCommand(40696, 0) -- rename last touched track
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
PostCreation()
reaper.Undo_EndBlock(scrName, -1)
