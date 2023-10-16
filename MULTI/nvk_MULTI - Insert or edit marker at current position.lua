-- @noindex
-- SCRIPT --
function Main()
    numMarkers = reaper.CountProjectMarkers(0)
    reaper.Main_OnCommand(40157, 0) --Insert marker at current position
    if reaper.CountProjectMarkers() == numMarkers then
        reaper.Main_OnCommand(40171, 0) --Insert/Edit marker at current position
    end
end

scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)