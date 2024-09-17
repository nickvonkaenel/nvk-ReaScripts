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
    if r.CountSelectedMediaItems(0) > 0 then
        GetItemsSnapOffsetsAndRemove()
        RepositionSelectedItemsSMART()
        r.SetExtState('nvk_PROPAGATE', 'auto', 'true', false)
        r.Main_OnCommand(r.NamedCommandLookup '_RS6fa1efbf615b0c385fc6bb27ca7865918dfc19a6', 0) -- nvk_PROPAGATE
        RestoreItemsSnapOffsets()
        r.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
    end
    tracks:Compact()
end)
