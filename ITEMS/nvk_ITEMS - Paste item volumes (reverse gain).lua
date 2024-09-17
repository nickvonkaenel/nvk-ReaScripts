-- @noindex
-- Pastes item volumes from clipboard but gain is reversed from 0 db so +6db becomes -6db and -6db becomes +6db
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local itemVolumesString = r.GetExtState('nvk_copyPaste', 'itemVolumes')
    if not itemVolumesString then return end
    local items = Items()
    local i = 0
    for volume in itemVolumesString:gmatch '([^,]+)' do
        i = i + 1
        if i > #items then break end
        local item = items[i]
        item.voldb = -spl2db(tonumber(volume) or 1)
        item.take.vol = 1
    end
end)
