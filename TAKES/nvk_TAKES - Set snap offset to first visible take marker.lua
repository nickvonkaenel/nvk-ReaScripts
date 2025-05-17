-- @noindex
-- Sets the snap offset to the first visible take marker in selected items. If no take markers are found, the snap offset will not be affected.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    for _, item in ipairs(Items.Selected()) do
        local take = item.take
        if take then
            local offset = take.offset
            for _, takemarker in ipairs(take.takemarkers) do
                if takemarker.srcpos >= offset then
                    local snapoffset = (takemarker.srcpos - offset) / take.rate
                    if snapoffset < item.length then item.snapoffset = snapoffset end
                    break
                end
            end
        end
    end
end)
