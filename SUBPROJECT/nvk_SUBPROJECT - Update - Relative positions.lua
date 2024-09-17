-- @noindex
-- Instructions: Run this script with your subproject items selected in the main project. The positions of the subproject items will be updated relative to the start of the first subproject item and the subproject items will be rendered and trimmed.
UPDATE_BEHAVIOR = 'Relative'
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

r.PreventUIRefresh(1)
r.Undo_BeginBlock()
SubProjectFix()
r.Undo_EndBlock(scr.name, -1)
r.PreventUIRefresh(-1)
