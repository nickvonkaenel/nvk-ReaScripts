--@noindex
--SCRIPT--
local scrName = ({ reaper.get_action_context() })[2]:match '.-([^/\\]+).lua$'
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
reaper.Main_OnCommand(40020, 0)
reaper.Main_OnCommand(40289, 0)
reaper.UpdateArrange()
reaper.UpdateTimeline()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
