-- @noindex
-- SETUP --
r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
local r = reaper
function Main()
    cursorPos = r.GetCursorPosition()
    item = GetItemUnderMouseCursor()
    if item then
        r.Main_OnCommand(40289, 0) -- unselect all items
        r.SetMediaItemSelected(item, true)
        groupSelect(item)
        items = SaveSelectedItems()
        r.Main_OnCommand(40513, 0) -- move edit cursor to mouse cursor
        r.Main_OnCommand(40757, 0) -- split items at edit cursor (select right)
        r.SetEditCurPos(cursorPos, 0, 0)
        for i, item in ipairs(items) do
            if r.ValidatePtr(item, 'MediaItem*') then
                r.SetMediaItemSelected(item, false)
            end
        end
    else
        r.Main_OnCommand(40759, 0) -- split at edit cursor (select right)
    end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
