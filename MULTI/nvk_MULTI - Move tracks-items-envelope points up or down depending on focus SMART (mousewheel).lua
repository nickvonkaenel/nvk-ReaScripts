-- @noindex
-- SCRIPT --
function Main()
    if val > 0 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup '_RSa1fcf46d1a968935c0e4676043eb766db2eafdbe', 0) --Script: nvk_MULTI - Move tracks-items-envelope points up depending on focus SMART.lua
    else
        reaper.Main_OnCommand(reaper.NamedCommandLookup '_RS3789ad7f9c210826b9d71f860e479ea1b8240894', 0) --Script: nvk_MULTI - Move tracks-items-envelope points down depending on focus SMART.lua
    end
end
is_new, name, sec, cmd, rel, res, val = reaper.get_action_context()
scrPath, scrName = ({ reaper.get_action_context() })[2]:match '(.-)([^/\\]+).lua$'
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
