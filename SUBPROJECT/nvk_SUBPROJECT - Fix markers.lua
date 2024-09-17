-- @noindex
-- Instructions: This script is intended to be run from a subproject. The start and end markers will be adjusted to match the start and end of the items in the subproject. This is also handled by the update scripts so you may not need to run this script depending on your workflow.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

r.PreventUIRefresh(1)
r.Undo_BeginBlock()
LoadSubprojectSettings()
SubProjectMarkers()
r.Undo_EndBlock(scr.name, -1)
r.PreventUIRefresh(-1)
