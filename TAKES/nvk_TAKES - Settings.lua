-- @noindex
SCRIPT_FOLDER = 'settings'
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
