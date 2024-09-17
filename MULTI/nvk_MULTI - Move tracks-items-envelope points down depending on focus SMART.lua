-- @noindex
-- SCRIPT --

function Main()
    focus = reaper.GetCursorContext()

    if focus == 0 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup '_RS8154c4c9d9bc098dc892a4f4fd58769c57cb887c', 0) --Script: nvk_TRACK - Move selected tracks down SMART.lua
        reaper.SetCursorContext(0, nil)
    end
    if focus == 1 then
        reaper.Main_OnCommand(40529, 0) --Item: Select item under mouse cursor (leaving other items selected)
        if reaper.CountSelectedMediaItems(0) == 0 then
            reaper.Main_OnCommand(reaper.NamedCommandLookup '_RS8154c4c9d9bc098dc892a4f4fd58769c57cb887c', 0) --Script: nvk_TRACK - Move selected tracks down SMART.lua
            reaper.SetCursorContext(0, nil)
        else
            reaper.Main_OnCommand(reaper.NamedCommandLookup '_RS82f2392ffbe9626a6a04afce08d60167201115a6', 0) --Script: nvk_ITEMS - Move selected items down one track SMART.lua
            reaper.SetCursorContext(1, nil)
        end
    end
    if focus == 2 then
        reaper.Main_OnCommand(41181, 0) --Envelopes: Move selected points down a little bit
        --reaper.SetCursorContext(2,nil)
    end
end

scrPath, scrName = ({ reaper.get_action_context() })[2]:match '(.-)([^/\\]+).lua$'
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
