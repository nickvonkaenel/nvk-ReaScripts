-- @noindex
-- USER CONFIG --
less = 0
greater = 1000
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    retval, retvals_csv = reaper.GetUserInputs(scr.name, 2, "Less than length (in seconds),Greater than length (in seconds)",
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
reaper.Undo_EndBlock(scr.name, -1)
