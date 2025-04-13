-- @noindex
-- Pastes names copied by nvk_TAKES - Copy take name(s).lua to selected items
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    if r.CountSelectedMediaItems(0) == 0 then return end
    local str = r.GetExtState('nvk_TAKES', 'take_name')
    if not str or str == '' then return end
    local items = Items.Selected()
    local i = 0
    for name in str:gmatch '[^\n]+' do
        i = i + 1
        local item = items[i]
        if not item then break end
        item.name = name
    end
end)
