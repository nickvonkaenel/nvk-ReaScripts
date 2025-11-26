--@noindex

function Main()
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_RS9ee27310565538ff2128f99c2acc8ab525d3d46e'), 0)
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_RS670f8c62f6690cfb43fc27c59feb671e36860ddb'), 0)
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_RS8a7afcdb07a2f63a50d1c80ab76d0fd3cb95e78e'), 0)
end

local _, scrName = ({ reaper.get_action_context() })[2]:match('(.-)([^/\\]+).lua$')
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
