-- @noindex
-- Toggle high resolution peaks on selected video items. Assumes default setting is disabled.
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end

run(function()
    local items = Items.Selected().video
    for _, item in ipairs(items) do
        local chunk = item.chunk
        if chunk:find('HIRESPEAKS') then
            chunk = chunk:gsub('\n[^\n]-HIRESPEAKS[^\n]+', '', 1)
        else
            chunk = chunk:gsub('<SOURCE VIDEO', '<SOURCE VIDEO\n    HIRESPEAKS 1', 1)
        end
        item.chunk = chunk
    end
end)
