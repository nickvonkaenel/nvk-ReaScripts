-- @noindex
-- Cycles the folder state of all tracks, instead of individually it finds the average of the track folder states and cycles all the tracks to the next state
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local tracks = Tracks.All().folder
    local compact_states = tracks.foldercompact
    local sum = 0
    for _, v in ipairs(compact_states) do
        sum = sum + v
    end
    local state = math.floor((sum / #compact_states) + 0.5)
    local new_state = (state + 1) % 3
    tracks.foldercompact = new_state
end)
