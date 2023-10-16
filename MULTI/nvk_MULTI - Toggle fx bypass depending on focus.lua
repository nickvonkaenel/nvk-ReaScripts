--@noindex

function Main()
    if reaper.GetCursorContext() == 0 then reaper.Main_OnCommand(8, 0) return end--fx bypass toggle track
    if reaper.CountSelectedMediaItems(0) > 0 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TGL_TAKEFX_BYP"), 0) --fx bypass toggle items
    else
        reaper.Main_OnCommand(8, 0) --fx bypass toggle track
    end
end

scrPath,scrName=({reaper.get_action_context()})[2]:match"(.-)([^/\\]+).lua$"
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)