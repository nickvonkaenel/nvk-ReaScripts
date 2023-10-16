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
    if reaper.CountSelectedMediaItems() > 0 then
        retval, retvals_csv = reaper.GetUserInputs("Reposition Items Across Tracks", 1,
                                  "Time (negative to use item end)", 0)
        if retval == false then
            return
        end
        repositionTime = tonumber(retvals_csv)
        if not repositionTime then return end
        startTime, endTime = reaper.BR_GetArrangeView(0)
        cursorPos = reaper.GetCursorPosition()
        if reaper.GetToggleCommandState(1156) == 1 then -- grouping override
            reaper.Main_OnCommand(1156, 0)
            groupingToggle = true
        end
        RepositionSelectedItemsAcrossTracks(repositionTime)
        reaper.SetEditCurPos(cursorPos, 0, 0)
        reaper.BR_SetArrangeView(0, startTime, endTime)
        if groupingToggle then
            reaper.Main_OnCommand(1156, 0) -- grouping override
        end 
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)

