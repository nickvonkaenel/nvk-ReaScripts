-- @noindex
-- Runs nvk_PROPAGATE's track mode with the last used settings. If no items are selected, the UI opens instead.
local r = reaper
if r.CountSelectedMediaItems(0) > 0 then
    r.SetExtState('nvk_PROPAGATE', 'auto', 'true', false)
end
r.Main_OnCommand(r.NamedCommandLookup('_RS6fa1efbf615b0c385fc6bb27ca7865918dfc19a6'), 0) -- nvk_PROPAGATE
