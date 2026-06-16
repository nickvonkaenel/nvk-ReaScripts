-- @noindex
-- This script is used to set up startup actions you want to run when Reaper starts. They will get called by the nvk_SHARED - Startup Actions - Run.lua script.
SCRIPT_FOLDER = 'startup'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
