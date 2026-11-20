-- @noindex
-- Copies the item positions and length of the selected items to the clipboard, can be pasted with the "Paste item positions and length" script
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    local entries = {}
    for i, item in ipairs(Items.Selected()) do
        entries[i] = string.format(
            [[

    {
        pos = %f,
        len = %f,
    },]],
            item.pos,
            item.len
        )
    end
    local str = 'return {' .. table.concat(entries) .. '\n}'
    r.CF_SetClipboard(str)
end)
