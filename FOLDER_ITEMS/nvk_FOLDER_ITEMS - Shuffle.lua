-- @noindex
-- Shuffles the order of folder items while preserving the column positions. Moves automation and restarts playback from the first item if the script is run while playback is active.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

run(function()
    local items = Items.Selected()
    if #items == 0 then return end
    local columns = Columns.New(items)
    local positions = {}
    for i, column in ipairs(columns) do
        positions[i] = column.s
    end
    positions = Tbl.Shuffle(positions)
    local repo_items = Items.New {}
    local repo_positions = {}
    for i, column in ipairs(columns) do
        local diff = positions[i] - column.s
        for j, item in ipairs(column.items) do
            table.insert(repo_items, item)
            table.insert(repo_positions, item.pos + diff)
        end
    end
    repo_items:Reposition(repo_positions)
    if r.GetPlayState() == 1 then r.SetEditCurPos(columns[1].s, false, true) end
end)
