-- @noindex
-- MiniMenu is a compact, customizable keyboard launcher powered by nvk_SEARCH.
-- Organize REAPER actions, FX, FX chains, track templates, and other search results
-- into folders with your own shortcuts, then launch them with a few keystrokes.
-- It also offers quick search and recent results for easy access to what you use most.
local r = reaper
r.SetExtState('nvk_SEARCH', 'MINIMENU', '1', false)
r.Main_OnCommand(r.NamedCommandLookup('_RS42ab70fd2ac65e9a003787709bb85f18c36dee52'), 0) -- Script: nvk_SEARCH.lua
