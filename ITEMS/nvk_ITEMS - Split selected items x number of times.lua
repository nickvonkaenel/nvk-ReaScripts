-- @noindex
-- USER CONFIG --
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
-- SCRIPT --

function Main()
    retval, retvals_csv = reaper.GetUserInputs(scr.name, 1, "Number of splits", "1")
    if not retval or not tonumber(retvals_csv) then return end
    local splits = tonumber(retvals_csv)
    local items = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        items[#items+1] = reaper.GetSelectedMediaItem(0, i)
    end
    for i = 1, #items do
        local item = items[i]
        local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        for i = 1, splits do
            local splitPos = itemPos + itemLen*i/(splits+1)
            item = reaper.SplitMediaItem(item, splitPos)
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
