-- @noindex
-- Select the takes you want to add stretch markers to and run the script. 0 will just put take markers at the start and end of the script. Positive numbers between -4 and 4 will pitch shift up or down. Anything above 5 will add increasing amounts of randomness.
-- SCRIPT --

scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"

function SaveSelectedItems()
    local items = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        table.insert(items, reaper.GetSelectedMediaItem(0, i))
    end
    return items
end

function GetItemPosition(item)
    local s = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local e = s + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    return s, e
end

function Main()
    local retval, retvals_csv = reaper.GetUserInputs("Set Take Slope", 1, "Slope (+-4) or 5+ for random", "0")
    if not retval then return end
    local slopeIn = 0
    if tonumber(retvals_csv) then slopeIn = tonumber(retvals_csv) end
    local items = SaveSelectedItems()
    reaper.Main_OnCommand(40796, 0) -- Clear take preserve pitch
    for i, item in ipairs(items) do
        local take = reaper.GetActiveTake(item)
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        reaper.DeleteTakeStretchMarkers(take, 0, reaper.GetTakeNumStretchMarkers(take))
        local idx = reaper.SetTakeStretchMarker(take, -1, 0)
        reaper.SetTakeStretchMarker(take, -1, itemLength * playrate)
        local slope = slopeIn
        if slope > 4 then
            slope = math.random() * math.min(4, (slope - 4)) / 4
            if math.random() > 0.5 then slope = slope * -1 end
        else
            slope = slope * 0.2499
        end
        local retval = reaper.SetTakeStretchMarkerSlope(take, idx, slope)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
