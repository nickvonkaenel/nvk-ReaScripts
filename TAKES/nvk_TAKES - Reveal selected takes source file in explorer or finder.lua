-- @noindex
-- Description
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

local function reveal_sourcefile(sourcefile)
    if os_is.win then
        r.ExecProcess('explorer.exe /select,"' .. sourcefile .. '"', -1)
    else
        r.CF_LocateInExplorer(sourcefile)
    end
end

local function normalize_sourcefile(sourcefile)
    if os_is.win and sourcefile then
        return sourcefile:gsub('/', '\\')
    end
    return sourcefile
end

run(function()
    local sourcefiles = {}
    local directories = {}
    -- remove duplicate directories
    for _, item in ipairs(Items.Selected()) do
        local sourcefile = normalize_sourcefile(item.sourcefile)
        local directory = sourcefile and sourcefile:match('^(.+)[/\\]')
        local directory_key = directory and (os_is.win and directory:lower() or directory)
        if directory_key and r.file_exists(sourcefile) and not directories[directory_key] then
            directories[directory_key] = true
            table.insert(sourcefiles, sourcefile)
        end
    end
    for _, sourcefile in ipairs(sourcefiles) do
        reveal_sourcefile(sourcefile)
    end
end)
