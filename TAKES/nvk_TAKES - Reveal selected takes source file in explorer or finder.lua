-- @noindex
-- Description
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    local sourcefiles = {}
    local directories = {}
    -- remove duplicate directories
    for _, item in ipairs(Items.Selected()) do
        local sourcefile = item.sourcefile
        local directory = sourcefile:match('^(.+)[/\\]')
        if not directories[directory] then
            directories[directory] = true
            table.insert(sourcefiles, sourcefile)
        end
    end
    for _, sourcefile in ipairs(sourcefiles) do
        r.CF_LocateInExplorer(sourcefile)
    end
end)
