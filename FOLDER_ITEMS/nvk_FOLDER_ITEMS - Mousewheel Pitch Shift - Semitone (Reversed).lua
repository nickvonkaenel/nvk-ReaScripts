-- @noindex
local is_new, _, _, _, _, _, val = reaper.get_action_context() -- has to be called first to get proper action context for mousewheel
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- USER CONFIG --
MOUSEWHEEL_PITCH_AMOUNT = -1 -- semitones to pitch up or down
-- SCRIPT --
MousewheelDefer(MousewheelPitchShift, true, is_new, val)
