-- @noindex
-- USER CONFIG --
splitLength = 1 -- default length
splitSpace = 1 --default spaces
-- SETUP--
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
sep = package.config:sub(1, 1)
dofile(debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep .. "functions.dat")
if not functionsLoaded then return end
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
reaper.Undo_EndBlock(scr.name, -1)

