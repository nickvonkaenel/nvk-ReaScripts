-- @noindex
-- Toggles the "Auto select" Folder Items setting in whichever settings preset the project uses, so
-- the option can be bound to a key or toolbar button without opening Settings.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
-- No project state changes here, so this stays out of an undo block.
local auto_select = not S.folder_items.auto_select
S.folder_items.auto_select = auto_select
Tbl.ToFile(WORKFLOW_CFG, scr.paths.settings)
r.SetExtState('nvk_FOLDER_ITEMS', 'settings_changed', '1', false)
if r.NVK_ReloadSettings then
    r.NVK_ReloadSettings()
end
-- The setting can also be changed from Settings, so this only guarantees a toolbar button matches
-- the preset from the moment the action runs.
r.SetToggleCommandState(scr.secID, scr.cmdID, auto_select and 1 or 0)
r.RefreshToolbar2(scr.secID, scr.cmdID)
