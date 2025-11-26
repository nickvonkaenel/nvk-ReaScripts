-- @noindex
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
local function get_folder(directoryPath)
    local retval, folder
    if r.APIExists('JS_Dialog_BrowseForFolder') then
        retval, folder = r.JS_Dialog_BrowseForFolder('Path to save items', directoryPath)
    else
        retval, folder = r.GetUserInputs('Path to save items', 1, 'Paste path here:,extrawidth=500', directoryPath)
        if folder:sub(-1, -1) == '\\' or folder:sub(-1, -1) == '/' then folder = folder:sub(1, -2) end
    end
    if retval then r.SetExtState(scr.name, 'path', folder, true) end
end

run(function()
    local directoryPath = r.GetExtState(scr.name, 'path')
    local items = Items()
    if not directoryPath or directoryPath == '' or #items == 0 then get_folder(directoryPath) end
    for i, item in ipairs(items) do
        item:Select(true)
        local initTake = item.take
        r.Main_OnCommand(40209, 0) --Item: Apply track/take FX to items
        local take = item.take --get new take
        if take ~= initTake then --check if render finished successfully
            local path, name = GetSourcePathName(take)
            r.Main_OnCommand(40129, 0) --delete active take from items
            item.take = initTake --restore initial take
            if path then CopyFile(path .. SEP .. name, directoryPath .. SEP .. name) end
        end
    end
end)
