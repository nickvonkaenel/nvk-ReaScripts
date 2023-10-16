-- @noindex
-- Mouse modifier: This script will be assigned to your mouse modifiers by the folder items - settings script. Not expected to be assigned to a shortcut.
-- USER CONFIG --
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    TrackDoubleClick()
    GetItemsSnapOffsetsAndRemove()
    RepositionSelectedItemsSMART()
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_RS6fa1efbf615b0c385fc6bb27ca7865918dfc19a6'), 0) -- nvk_PROPAGATE
    RestoreItemsSnapOffsets()
    reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scr.name, -1)
