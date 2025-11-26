-- @noindex
-- Applies that last used settings for nvk_PROPAGATE to selected items. If no items are selected, the script will open the UI instead.
local r = reaper
if r.CountSelectedMediaItems(0) > 0 then r.SetExtState('nvk_PROPAGATE', 'auto', 'true', false) end
r.Main_OnCommand(r.NamedCommandLookup('_RS6fa1efbf615b0c385fc6bb27ca7865918dfc19a6'), 0) -- nvk_PROPAGATE
