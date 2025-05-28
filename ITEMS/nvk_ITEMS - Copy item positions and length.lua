-- @noindex
-- Copies the item positions and length of the selected items to the clipboard, can be pasted with the "Paste item positions and length" script
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    local str = 'return {'
    for _, item in ipairs(Items.Selected()) do
        str = str
            .. string.format(
                [[

    {
        pos = %f,
        len = %f,
    },]],
                item.pos,
                item.len
            )
    end
    str = str .. '\n}'
    r.CF_SetClipboard(str)
end)
