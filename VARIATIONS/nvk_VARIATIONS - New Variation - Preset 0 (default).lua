-- @noindex
--[[
    Select the items you want to create a variation from and run the script.
    A new variation will be created based on the corresponding preset settings in nvk_VARIATIONS.
]]
local r = reaper
r.Undo_BeginBlock()
r.SetExtState('nvk_VARIATIONS', 'preset', 'default', false)
r.SetExtState('nvk_VARIATIONS', 'var_amt', '1', false)
r.Main_OnCommand(r.NamedCommandLookup '_RS27a8818a7d4eb2c7e02a8893c95d52ae96852382', 0) -- nvk_VARIATIONS
r.Undo_EndBlock('nvk_VARIATIONS - New Variation - Preset 0 (default)', -1)
