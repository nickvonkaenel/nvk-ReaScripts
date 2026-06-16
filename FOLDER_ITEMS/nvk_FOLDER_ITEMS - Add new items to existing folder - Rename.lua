-- @noindex
-- Select parent track and run script. It will add blank items matching contiguous items on the children tracks within time selection
-- if folder items are selected, it will open the rename script instead
-- legacy script, use nvk_FOLDER_ITEMS.lua or nvk_FOLDER_ITEMS - Update (manual).lua instead ideally for full features
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
    AddNewItemsToExistingFolder(true)
end)
