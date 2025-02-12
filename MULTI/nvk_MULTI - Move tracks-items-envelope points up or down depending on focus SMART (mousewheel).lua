-- @noindex
-- SCRIPT --
local _, filename, _, _, _, _, val = reaper.get_action_context()
local scrName = filename:match '.-([^/\\]+).lua$'
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
if val > 0 then
    reaper.Main_OnCommand(reaper.NamedCommandLookup '_RSa1fcf46d1a968935c0e4676043eb766db2eafdbe', 0) --Script: nvk_MULTI - Move tracks-items-envelope points up depending on focus SMART.lua
else
    reaper.Main_OnCommand(reaper.NamedCommandLookup '_RS3789ad7f9c210826b9d71f860e479ea1b8240894', 0) --Script: nvk_MULTI - Move tracks-items-envelope points down depending on focus SMART.lua
end
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
