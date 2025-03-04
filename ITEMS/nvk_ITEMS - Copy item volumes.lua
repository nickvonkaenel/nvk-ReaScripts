-- @noindex
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local items = Items()
    if #items == 0 then return end
    local vols = {}
    for i, item in ipairs(items) do
        local take = item.take
        vols[i] = db2spl(item.vol + (take and take.vol or 0))
    end
    r.SetExtState('nvk_copyPaste', 'itemVolumes', table.concat(vols, ','), false)
end)
