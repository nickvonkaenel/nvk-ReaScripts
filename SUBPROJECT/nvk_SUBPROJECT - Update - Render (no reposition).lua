-- @noindex
-- Instructions: Run this script with your subproject items selected in the main project. The subproject items will be rendered. If run with no subproject items selected, the current project will be rendered (if it has subproject markers).
UPDATE_BEHAVIOR = 'None'
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

r.PreventUIRefresh(1)
r.Undo_BeginBlock()
if not SubProjectFix() and HasSubprojectMarkers() then -- Render current project if no subproject items are selected and it has subproject markers
    r.Main_OnCommand(42332, 0) -- File: Save project and render RPP-PROX
end
r.Undo_EndBlock(scr.name, -1)
r.PreventUIRefresh(-1)
