--@noindex
--SCRIPT--
function Main()
    reaper.Main_OnCommand(40020, 0)
    reaper.Main_OnCommand(40289, 0)
end

scrPath, scrName = ({ reaper.get_action_context() })[2]:match '(.-)([^/\\]+).lua$'
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.UpdateTimeline()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
