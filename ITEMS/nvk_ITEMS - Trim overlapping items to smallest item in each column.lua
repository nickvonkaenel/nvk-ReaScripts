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
    for _, column in ipairs(Columns(Items())) do
        local minlenitem = column.items:MinLenItem()
        assert(minlenitem, 'No items in column')
        for i, item in ipairs(column.items) do
            item:Trim(minlenitem.s, minlenitem.e)
        end
    end
end)