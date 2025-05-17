-- @noindex
-- Glues selected items independently and sets the take name to the same name as the current take name
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    local glued_items = Items {}
    for _, item in ipairs(Items.Selected()) do
        local name = item.name
        item:Select(true)
        if item.midi then
            r.Main_OnCommand(40209, 0) -- Item: Apply track/take FX to items
        end
        r.Main_OnCommand(40362, 0) -- Item: Glue items, ignoring time selection
        local glued_item = Item.Selected()
        glued_item.name = name
        table.insert(glued_items, glued_item)
    end
    glued_items:Select(true)
end)
