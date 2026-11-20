-- @noindex
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
-- Asks for the folder the rendered files are copied to and remembers it. Returns the folder, or nil when the prompt
-- is cancelled or left empty, which keeps the folder remembered before.
local function choose_folder(directoryPath)
    local confirmed, folder
    if r.APIExists('JS_Dialog_BrowseForFolder') then
        local retval
        retval, folder = r.JS_Dialog_BrowseForFolder('Path to save items', directoryPath)
        confirmed = retval == 1 -- 0 when cancelled, -1 on an error
    else
        confirmed, folder = r.GetUserInputs('Path to save items', 1, 'Paste path here:,extrawidth=500', directoryPath)
        if folder:sub(-1, -1) == '\\' or folder:sub(-1, -1) == '/' then
            folder = folder:sub(1, -2)
        end
    end
    if not confirmed or not folder or folder == '' then
        return nil
    end
    r.SetExtState(scr.name, 'path', folder, true)
    return folder
end

local not_copied, destination = run(function()
    local directoryPath = r.GetExtState(scr.name, 'path')
    local items = Items()
    if directoryPath == '' or #items == 0 then
        directoryPath = choose_folder(directoryPath)
        if not directoryPath then
            return
        end
    end
    local failed = {}
    for i, item in ipairs(items) do
        item:Select(true)
        local initTake = item.take
        r.Main_OnCommand(40209, 0) --Item: Apply track/take FX to items
        local take = item.take --get new take
        if take ~= initTake then --check if render finished successfully
            local path, name = GetSourcePathName(take.take)
            r.Main_OnCommand(40129, 0) --delete active take from items
            item.take = initTake --restore initial take
            if path then
                local copied, message = CopyFile(path .. SEP .. name, directoryPath .. SEP .. name)
                if not copied then
                    failed[#failed + 1] = message
                end
            end
        end
    end
    items:Select(true) -- rendering selected them one at a time
    return failed, directoryPath
end)

if not_copied and #not_copied > 0 then
    r.MB(
        string.format(
            'Could not copy %d rendered %s to %s:\n\n%s',
            #not_copied,
            #not_copied == 1 and 'file' or 'files',
            destination,
            table.concat(not_copied, '\n')
        ),
        'Error',
        0
    )
end
