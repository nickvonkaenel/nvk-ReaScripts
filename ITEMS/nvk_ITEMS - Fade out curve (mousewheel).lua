-- @noindex
-- USER CONFIG --
MOUSEWHEEL_SELECT_ITEM_UNDER_MOUSE = true
MOUSEWHEEL_FADECURVE_AMOUNT = 0.25 -- higher values will change the curve faster (curves go from -1 to 1)
MOUSEWHEEL_FADECURVE_OUT = true -- if true, fade out, if false, fade in
-- SETUP --
local is_new, _, _, _, _, _, val = reaper.get_action_context() -- has to be called first to get proper action context for mousewheel
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
MousewheelDefer(MousewheelFadeCurve, true, is_new, val, nil, MousewheelFadeCurveFinalize)
