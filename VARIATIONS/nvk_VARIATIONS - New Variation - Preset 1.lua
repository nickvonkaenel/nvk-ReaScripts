-- @noindex
--[[
    Select the items you want to create a variation from and run the script.
    A new variation will be created based on the corresponding preset settings in nvk_VARIATIONS.
]]
local r = reaper
r.Undo_BeginBlock()
r.SetExtState('nvk_VARIATIONS', 'preset', '1', false)
r.SetExtState('nvk_VARIATIONS', 'var_amt', '1', false)
r.Main_OnCommand(r.NamedCommandLookup('_RS27a8818a7d4eb2c7e02a8893c95d52ae96852382'), 0) -- nvk_VARIATIONS
-- nvk_VARIATIONS consumes both keys when it runs the preset. When it does not (its window was already open and only
-- came forward), clear them here: left behind, they would make its next launch run this preset instead of opening
-- the window.
r.DeleteExtState('nvk_VARIATIONS', 'preset', true)
r.DeleteExtState('nvk_VARIATIONS', 'var_amt', true)
r.Undo_EndBlock('nvk_VARIATIONS - New Variation - Preset 1', -1)
