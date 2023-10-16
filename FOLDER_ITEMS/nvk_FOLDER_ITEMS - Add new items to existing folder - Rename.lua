-- @noindex
-- Select parent track and run script. It will add blank items matching contiguous items on the children tracks within time selection
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --
if not reaper.HasExtState(scrName, "mm") then
    reaper.SetExtState(scrName, "mm", "true", true)
    is_new_value, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
    actionID = reaper.ReverseNamedCommandLookup(cmdID)
    actionID = "_" .. actionID
    if actionID ~= reaper.GetMouseModifier("MM_CTX_TRACK_DBLCLK", 0, "") then
        if reaper.ShowMessageBox(
            "This script will change the double click mouse modifiers for tracks\n\nIf you would prefer to set up mouse modifiers manually, choose \'cancel\', then edit the script and change mouse_modifiers to \'false\'",
            "Warning", 1) ~= 1 then
            return
        end
        reaper.ShowMessageBox("Double click on a black space in the parent track to add folder items", "Instructions", 0)
        reaper.SetMouseModifier("MM_CTX_TRACK_DBLCLK", 0, actionID)
        return
    end
end

function GetFolderItems(track) --overrides default function to do time selection
    ls, le = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if ls == le then
        ls = 0
        le = math.huge
        if itemsSelected then
            ls = items[1][2] -- start of items
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
                table.insert(folderItems, {item, itemPos, itemEnd, name, doNum})
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
        if IsFolderItem(reaper.GetSelectedMediaItem(0,0)) then
            reaper.Main_OnCommand( reaper.NamedCommandLookup("_RSe8733f58b84754de32c3dd2cdd466a1ac6231322"), 0 )
            return
        end
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

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)

