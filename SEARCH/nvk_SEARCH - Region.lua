-- @noindex
local r = reaper
local filter = ({ r.get_action_context() })[2]:match('%- ([^-]+)%.lua$'):lower()
r.SetExtState('nvk_SEARCH', 'FILTER', filter, false)
r.Main_OnCommand(r.NamedCommandLookup '_RS42ab70fd2ac65e9a003787709bb85f18c36dee52', 0) -- Script: nvk_SEARCH.lua
