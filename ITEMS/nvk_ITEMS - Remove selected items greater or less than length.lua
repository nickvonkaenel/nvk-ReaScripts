-- @noindex
-- USER CONFIG --
less = 0
greater = 1000
-- SETUP --
function GetPath(a, b)
    if not b then
        b = ".dat"
    end
    local c = scrPath .. "Data" .. sep .. a .. b;
    return c
end
OS = reaper.GetOS()
sep = OS:match "Win" and "\\" or "/"
scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"
loadfile(GetPath "functions")()
if not functionsLoaded then
    return
end
-- SCRIPT --
function Main()
    retval, retvals_csv = reaper.GetUserInputs(scrName, 2, "Less than length (in seconds),Greater than length (in seconds)",
                              less .. "," .. greater)

    if retval == false then
        return
    end

    inputTable = {}
    for input in string.gmatch(retvals_csv, '([^,]+)') do
        tonumber(input)
        table.insert(inputTable, input)
    end
    less = tonumber(inputTable[1])
    greater = tonumber(inputTable[2])
    if less and greater then
        for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
            item = reaper.GetSelectedMediaItem(0, i)
            itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            if itemLen < less or itemLen > greater then
                track = reaper.GetMediaItem_Track(item)
                reaper.DeleteTrackMediaItem(track, item)
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
