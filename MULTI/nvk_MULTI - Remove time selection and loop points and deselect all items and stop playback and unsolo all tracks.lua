--@noindex
--SCRIPT--
local r = reaper
local scrName = ({ r.get_action_context() })[2]:match('.-([^/\\]+).lua$')
r.Undo_BeginBlock()
r.PreventUIRefresh(1)
r.Main_OnCommand(40020, 0)
r.Main_OnCommand(40289, 0)
r.Main_OnCommand(40340, 0) -- Track: Unsolo all tracks
r.Main_OnCommand(1016, 0) -- Transport: Stop
r.UpdateArrange()
r.UpdateTimeline()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scrName, -1)
