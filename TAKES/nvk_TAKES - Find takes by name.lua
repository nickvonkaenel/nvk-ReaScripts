-- @noindex
-- SETUP --
SCRIPT_FOLDER = 'simple'
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
table.insert(bar.buttons, 1, 'pin')

s.str = s.str or ''

SimpleDraw = function()
    local rv
    if scr.init then ImGui.SetKeyboardFocusHere(ctx) end
    rv, s.str = ImGui.InputText(ctx, 'Name', s.str, ImGui.InputTextFlags_AutoSelectAll)
    if ImGui.IsItemDeactivatedAfterEdit(ctx) and Keyboard.Enter() then Actions.Run() end
end

SimpleRun = function()
    local searchString = s.str:lower()
    Items.All():Filter(function(item) return item.name:lower():find(searchString) end):Select(true)
    r.Main_OnCommand(41622, 0) -- View: Toggle zoom to selected items
end
