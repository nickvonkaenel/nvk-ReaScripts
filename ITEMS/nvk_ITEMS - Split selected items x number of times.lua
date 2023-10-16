-- @noindex
-- USER CONFIG --
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function Main()
    retval, retvals_csv = reaper.GetUserInputs(scrName, 1, "Number of splits", "1")
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
reaper.Undo_EndBlock(scrName, -1)
