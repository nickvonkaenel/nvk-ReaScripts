-- @noindex
-- USER CONFIG --
splitLength = 1 -- default length
splitSpace = 1 --default spaces
-- SETUP --
function GetPath(a,b)if not b then b=".dat"end;local c=scrPath.."Data"..sep..a..b;return c end;OS=reaper.GetOS()sep=OS:match"Win"and"\\"or"/"scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"loadfile(GetPath"functions")()if not functionsLoaded then return end
-- SCRIPT --

function Main()
    if reaper.CountSelectedMediaItems() > 0 then
        retval, retvals_csv = reaper.GetUserInputs("Title", 2, "Length (in seconds),Space (in seconds)",
                                  splitLength .. "," .. splitSpace)

        if retval == false then
            return
        end

        inputTable = {}
        for input in string.gmatch(retvals_csv, '([^,]+)') do
            tonumber(input)
            table.insert(inputTable, input)
        end
        splitLength = tonumber(inputTable[1])
        splitSpace = tonumber(inputTable[2])
        if splitLength < 0.01 then
            reaper.ShowMessageBox("Split length too small","Error", 1)
            return
        end

        repositionTime = -splitSpace
        startTime, endTime = reaper.BR_GetArrangeView(0)
        cursorPos = reaper.GetCursorPosition()
        if reaper.GetToggleCommandState(1156) == 1 then -- grouping override
            reaper.Main_OnCommand(1156, 0)
            groupingToggle = true
        end
        SplitItemsXSeconds(splitLength)
        RepositionSelectedItems(repositionTime)
        reaper.SetEditCurPos(cursorPos, 0, 0)
        reaper.BR_SetArrangeView(0, startTime, endTime)
        if groupingToggle then
            reaper.Main_OnCommand(1156, 0)
        end -- grouping override
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)

