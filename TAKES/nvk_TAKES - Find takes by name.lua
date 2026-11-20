-- @noindex
-- SETUP --
SCRIPT_FOLDER = 'simple'
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
table.insert(bar.buttons, 1, 'pin')

s.str = s.str or ''

function SimpleDraw()
    local rv
    if scr.init then
        ImGui.SetKeyboardFocusHere(ctx)
    end
    rv, s.str = ImGui.InputText(ctx, 'Name', s.str, ImGui.InputTextFlags_AutoSelectAll)
    if ImGui.IsItemDeactivatedAfterEdit(ctx) and Keyboard.Enter() then
        Actions.Run()
    end
end

function SimpleRun()
    local searchString = s.str:lower()
    Items.All()
        :Filter(function(item)
            -- An item without a take (an empty item) has no name to match.
            local name = item.name
            return name ~= nil and name:lower():find(searchString, 1, true) ~= nil
        end)
        :Select(true)
    r.Main_OnCommand(41622, 0) -- View: Toggle zoom to selected items
end
