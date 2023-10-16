-- @noindex
-- This script aligns items in various ways depending on what position they are currently in. Select some items and run the script a few times to see what it does.
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function SaveSelectedItemsString(items)
    selectedItemsString = ""
    for i, item in ipairs(items) do
        selectedItemsString = selectedItemsString .. reaper.BR_GetMediaItemGUID(item)
    end

    section, key = "nvk_align", "items"

    if selectedItemsString == reaper.GetExtState(section, key) then
        return true
    else
        if reaper.HasExtState(section, key) then
            reaper.DeleteExtState(section, key, 0)
        end
        reaper.SetExtState(section, key, selectedItemsString, 0)
        return false
    end
end

function CheckSelectedItemsString(items)
    selectedItemsString = ""
    for i, item in ipairs(items) do
        selectedItemsString = selectedItemsString .. reaper.BR_GetMediaItemGUID(item)
    end

    section, key = "nvk_align", "items"

    if selectedItemsString == reaper.GetExtState(section, key) then
        return true
    else
        return false
    end
end

function SaveSelectedItemsTracksString(items)
    selectedItemsTracksString = ""
    for i, item in ipairs(items) do
        track = reaper.GetMediaItem_Track(item)
        selectedItemsTracksString = selectedItemsTracksString .. reaper.BR_GetMediaTrackGUID(track)
    end

    section, key = "nvk_align", "tracks"

    if selectedItemsTracksString == reaper.GetExtState(section, key) then
        return true
    else
        if reaper.HasExtState(section, key) then
            reaper.DeleteExtState(section, key, 0)
        end
        reaper.SetExtState(section, key, selectedItemsTracksString, 0)
        return false
    end
end

function RestoreSelectedItemsTracksString(items)
    section, key = "nvk_align", "tracks"
    selectedItemsTracksString = reaper.GetExtState(section, key)
    i = 1
    firstTrack = reaper.GetMediaItem_Track(items[1])
    for guid in selectedItemsTracksString:gmatch '{.-}' do
        track = reaper.BR_GetMediaTrackByGUID(0, guid)
        if i == 1 and track ~= firstTrack then
            return
        end
        if track then
            reaper.MoveMediaItemToTrack(items[i], track)
            i = i + 1
        end
    end
end

function IsAligned(items)
    for i, item in ipairs(items) do
        if i == 1 then
            position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        else
            if position ~= reaper.GetMediaItemInfo_Value(item, "D_POSITION") then
                return false
            end
        end
    end
    return true
end

function IsSameTrack(items)
    for i, item in ipairs(items) do
        if i == 1 then
            track = reaper.GetMediaItemTrack(item)
        else
            if track ~= reaper.GetMediaItemTrack(item) then
                return false
            end
        end
    end
    return true
end

function IsSequentialTracks(items)
    for i, item in ipairs(items) do
        if i == 1 then
            track = reaper.GetMediaItemTrack(item)
            idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        else
            track = reaper.GetMediaItemTrack(item)
            if idx + i - 1 ~= reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") then
                return false
            end
        end
    end
    return true
end

function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function IsSequentialItems(items)
    for i, item in ipairs(items) do
        if i == 1 then
            position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            itemEnd = position + length
        else
            if round(itemEnd, 3) == round(reaper.GetMediaItemInfo_Value(item, "D_POSITION"), 3) then
                length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                itemEnd = itemEnd + length
            else
                return false
            end
        end
    end
    return true
end

function ExplodeOnTracksBelow(items)
    for i, item in ipairs(items) do
        if i > 1 then
            track = reaper.GetTrack(0, idx + i - 1 - 1)
            if not track then
                reaper.InsertTrackAtIndex(idx + i - 1 - 1, true)
                track = reaper.GetTrack(0, idx + i - 1 - 1)
            end
            reaper.MoveMediaItemToTrack(item, track)
        else
            track = reaper.GetMediaItemTrack(item)
            idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        end
    end
end

function AlignToFirstItem(items)
    for i, item in ipairs(items) do
        if i == 1 then
            position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        else
            reaper.SetMediaItemPosition(item, position, 0)
        end
    end
end

function SequentialItems(items)
    for i, item in ipairs(items) do
        if i == 1 then
            position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            itemEnd = position + length
        else
            reaper.SetMediaItemPosition(item, itemEnd, 0)
            length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            itemEnd = itemEnd + length
        end
    end
end

function MoveToSameTrack(items)
    for i, item in ipairs(items) do
        if i == 1 then
            track = reaper.GetMediaItemTrack(item)
        else
            reaper.MoveMediaItemToTrack(item, track)
        end
    end
end

function SaveItemPositionsString(items)
    itemPositions = {}
    for i, item in ipairs(items) do
        position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        itemPositions[i] = position
    end

    table:sort(itemPositions)

    itemPositionsString = ""

    for i = 1, #itemPositions do
        itemPositionsString = itemPositionsString .. itemPositions[i] .. ","
    end

    section, key = "nvk_align", "itemPositions"
    if reaper.HasExtState(section, key) then
        reaper.DeleteExtState(section, key, 0)
    end
    reaper.SetExtState(section, key, itemPositionsString, 0)
end

function RestoreItemPositionsString(items)
    firstItemPosition = position
    itemPositionsString = reaper.GetExtState("nvk_align", "itemPositions")
    i = 1
    for position in itemPositionsString:gmatch "(.-)," do
        if i == 1 then
            positionOffset = firstItemPosition - position
        end
        if items[i] then
            reaper.SetMediaItemInfo_Value(items[i], "D_POSITION", position + positionOffset)
        end
        i = i + 1
    end
end

function Initialize()
    if not CheckSelectedItemsString(items) then
        section, key = "nvk_align", "itemPositions"
        if reaper.HasExtState(section, key) then
            reaper.DeleteExtState(section, key, 0)
        end
        section, key = "nvk_align", "moveTracker"
        if reaper.HasExtState(section, key) then
            reaper.DeleteExtState(section, key, 0)
        end
        section, key = "nvk_align", "items"
        if reaper.HasExtState(section, key) then
            reaper.DeleteExtState(section, key, 0)
        end
        section, key = "nvk_align", "tracks"
        if reaper.HasExtState(section, key) then
            reaper.DeleteExtState(section, key, 0)
        end
        -- section, key = "nvk_align", "saveTracker"
        -- if reaper.HasExtState(section, key) then reaper.DeleteExtState(section, key, 0) end
    end
end

function Main()
    if reaper.CountSelectedMediaItems(0) > 1 then
        reaper.Undo_BeginBlock()
        items = SaveSelectedItems()
        Initialize()
        aligned = IsAligned(items)
        sameTrack = IsSameTrack(items)
        sequentialTracks = IsSequentialTracks(items)
        sequentialItems = IsSequentialItems(items)

        if aligned and sequentialTracks then
            if reaper.GetExtState("nvk_align", "moveTracker") == "2" and CheckSelectedItemsString(items) then -- and reaper.GetExtState("nvk_align", "saveTracker") == "2"
                RestoreItemPositionsString(items)
                RestoreSelectedItemsTracksString(items)
            else
                MoveToSameTrack(items)
                SequentialItems(items)
                if CheckSelectedItemsString(items) then
                    section, key = "nvk_align", "moveTracker"
                    if reaper.HasExtState(section, key) then
                        reaper.DeleteExtState(section, key, 0)
                    end
                    reaper.SetExtState(section, key, "1", 0)
                end
            end
        else
            if sameTrack then
                if sequentialItems then
                    if reaper.GetExtState("nvk_align", "moveTracker") == "1" and CheckSelectedItemsString(items) then
                        RestoreItemPositionsString(items)
                    else
                        ExplodeOnTracksBelow(items)
                        AlignToFirstItem(items)
                        if CheckSelectedItemsString(items) then
                            section, key = "nvk_align", "moveTracker"
                            if reaper.HasExtState(section, key) then
                                reaper.DeleteExtState(section, key, 0)
                            end
                            reaper.SetExtState(section, key, "2", 0)
                        end
                    end
                else
                    SaveItemPositionsString(items)
                    SaveSelectedItemsString(items)
                    SequentialItems(items)
                    section, key = "nvk_align", "moveTracker"
                    if reaper.HasExtState(section, key) then
                        reaper.DeleteExtState(section, key, 0)
                    end
                    reaper.SetExtState(section, key, "0", 0)
                end
            else
                SaveItemPositionsString(items)
                SaveSelectedItemsString(items)
                SaveSelectedItemsTracksString(items)
                ExplodeOnTracksBelow(items)
                AlignToFirstItem(items)
                -- section, key = "nvk_align", "saveTracker"
                -- if reaper.HasExtState(section, key) then reaper.DeleteExtState(section, key, 0) end
                -- reaper.SetExtState(section, key, "2", 0)
                section, key = "nvk_align", "moveTracker"
                if reaper.HasExtState(section, key) then
                    reaper.DeleteExtState(section, key, 0)
                end
                reaper.SetExtState(section, key, "0", 0)
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
