-- @noindex
-- USER CONFIG --
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
run(function()
    Items.Selected()
        :Filter(function(item)
            return not item.folder
        end)
        :Unselect()
    r.SetExtState('nvk_FOLDER_ITEMS', 'projUpdateFreeze', 'true', false)
end)
