-- @noindex
-- Use this script to update folder items manually after making changes to the folder items. This script is not necessary if you are using the main nvk_FOLDER_ITEMS script and have Folder Items 'enabled', but can be useful for certain situations.
-- One common use case is when you have an extremely large project with >5000 folder items. In this case, you might start to experience a bit of lag when making changes. In this case, you can disable Folder Items and use this script to update the folder items manually every once in a while.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
FolderItems.Fix()
