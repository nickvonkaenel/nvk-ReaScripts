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
    TrackDoubleClick()
    GetItemsSnapOffsetsAndRemove()
    RepositionSelectedItemGroupsSMART()
    RestoreItemsSnapOffsets()
    reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
    tracks:Compact()
end)
