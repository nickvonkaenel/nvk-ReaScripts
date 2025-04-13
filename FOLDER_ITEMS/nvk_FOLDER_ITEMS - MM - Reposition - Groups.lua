-- @noindex
-- Mouse modifier: This script will be assigned to your mouse modifiers by the folder items - settings script. Not expected to be assigned to a shortcut.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local tracks = Tracks.All():Uncompact()
    local track = Track.Selected()
    if track then track:Children(true):Items(Column.TimeSelection()):Select(true) end
    GetItemsSnapOffsetsAndRemove()
    RepositionSelectedItemGroupsSMART()
    RestoreItemsSnapOffsets()
    r.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
    r.PreventUIRefresh(-1)
    r.Main_OnCommand(40031, 0) -- View: Zoom time selection
    r.PreventUIRefresh(1)
    tracks:Compact()
end)
