-- @noindex
-- This script will fade in or out the item nearest to the mouse cursor depending on which side of the item the cursor is on.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT ---
run(function()
    local item, cursorPos = Item.NearestToMouse()
    if not item or not cursorPos then return end
    local isFadeIn = cursorPos < item.midpos
    if isFadeIn then
        r.Main_OnCommand(r.NamedCommandLookup '_RSbe9ab53bf8517e6ad4f192cbc491ab05b0d05e5d', 0) -- Script: nvk_FOLDER_ITEMS - Fade in.lua
    else
        r.Main_OnCommand(r.NamedCommandLookup '_RS80e9967ca2a86e09fe8b504e0c7c67f23600de86', 0) -- Script: nvk_FOLDER_ITEMS - Fade out.lua
    end
end)

