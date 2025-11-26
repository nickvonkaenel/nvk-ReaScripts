-- @noindex
-- SETUP --
local is_new, _, _, _, _, _, val = reaper.get_action_context() -- has to be called first to get proper action context for mousewheel
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
MOUSEWHEEL_VOLUME_AMOUNT = 1 -- dB to increase or decrease volume
MousewheelDefer(MousewheelVolume, true, is_new, val)
