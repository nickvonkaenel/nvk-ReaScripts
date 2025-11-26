-- @noindex
-- Randomizes the envelope points in the time selection of the selected tracks.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end

run(function()
    local time_selection = Column.TimeSelection()
    if not time_selection then time_selection = { s = -math.huge, e = math.huge } end
    for _, track in ipairs(Tracks.Selected()) do
        for _, envelope in ipairs(track.envelopes) do
            local points = envelope.points
            for _, point in ipairs(points) do
                if point.time >= time_selection.s and point.time <= time_selection.e then
                    point.value = math.random()
                end
            end
            envelope.points = points
        end
    end
    if r.GetPlayState() == 1 then
        r.Main_OnCommand(1007, 0) -- Transport: Play
    end
end)
