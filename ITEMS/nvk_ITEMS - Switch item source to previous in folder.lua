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
run(function()
    Items().folder:Unselect()
    r.Main_OnCommand(r.NamedCommandLookup('_XENAKIOS_SISFTPREVIF'), 0) -- Xenakios/SWS: Switch item source file to previous in folder
end)
