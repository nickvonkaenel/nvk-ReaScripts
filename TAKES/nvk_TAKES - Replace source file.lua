-- @noindex
-- Replaces the source file of selected takes with a file provided by the user.
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    local rv, source_file = r.GetUserFileNameForRead('', 'Select source file', '')
    if not rv then
        return
    end
    for _, item in ipairs(Items.Selected()) do
        local take = item.take
        if take then
            take:ReplaceSourceFile(source_file)
        end
    end
end)
