-- @noindex
-- Select parent track and run script. It will add blank items matching contiguous items on the children tracks within time selection
-- legacy script, use nvk_FOLDER_ITEMS.lua or nvk_FOLDER_ITEMS - Update (manual).lua instead ideally for full features
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(AddNewItemsToExistingFolder)
