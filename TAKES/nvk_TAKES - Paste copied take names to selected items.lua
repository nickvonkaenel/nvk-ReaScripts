-- @noindex
-- Pastes names copied by nvk_TAKES - Copy take name(s).lua to selected items
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    if r.CountSelectedMediaItems(0) == 0 then
        return
    end
    local str = r.GetExtState('nvk_TAKES', 'take_name')
    if not str or str == '' then
        return
    end
    local items = Items.Selected()
    -- Copy take name(s) writes one line per item it copied, so every line, a blank one included, belongs to the item
    -- in the same place. A blank line (a take without a name, or an item without a take) leaves its item's name as
    -- it is; skipping it would move every later name onto the item before its own.
    local i = 0
    for name in (str .. '\n'):gmatch('(.-)\n') do
        i = i + 1
        local item = items[i]
        if not item then
            break
        end
        if name ~= '' then
            item.name = name
        end
    end
end)
