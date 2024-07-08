-- @noindex
-- SETUP --
local r = reaper
sep = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match("@(.+[/\\])") .. DATA .. sep
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    Items().folder:Unselect()
    r.Main_OnCommand(r.NamedCommandLookup("_XENAKIOS_SISFTPREVIF"), 0) -- Xenakios/SWS: Switch item source file to previous in folder
end)
