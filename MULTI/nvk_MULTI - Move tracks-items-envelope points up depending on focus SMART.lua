-- @noindex
-- SCRIPT --

function Main()
    local focus = reaper.GetCursorContext()

    if focus == 0 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup '_RS90f1766432b9584da292a0f204465bb6e1483c20', 0) --Script: nvk_TRACK - Move selected tracks up SMART.lua
        reaper.SetCursorContext(0, nil)
    end
    if focus == 1 then
        reaper.Main_OnCommand(40529, 0) --Item: Select item under mouse cursor (leaving other items selected)
        if reaper.CountSelectedMediaItems(0) == 0 then
            reaper.Main_OnCommand(reaper.NamedCommandLookup '_RS90f1766432b9584da292a0f204465bb6e1483c20', 0) --Script: nvk_TRACK - Move selected tracks up SMART.lua
            reaper.SetCursorContext(0, nil)
        else
            reaper.Main_OnCommand(reaper.NamedCommandLookup '_RS922c53d0cd41794355be7256eb855c9842223af5', 0) --Script: nvk_ITEMS - Move selected items up one track SMART.lua
            reaper.SetCursorContext(1, nil)
        end
    end
    if focus == 2 then
        reaper.Main_OnCommand(41180, 0) --Envelopes: Move selected points up a little bit
        --reaper.SetCursorContext(2,nil)
    end
end

local _, scrName = ({ reaper.get_action_context() })[2]:match '(.-)([^/\\]+).lua$'
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
