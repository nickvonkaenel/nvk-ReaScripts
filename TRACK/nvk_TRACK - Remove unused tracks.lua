-- @noindex
-- Removes tracks that are unused, i.e. unarmed/unnamed and no items, sends/receives, fx, or envelopes.
-- SETUP --
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    for _, track in ipairs(Tracks.All().unused) do
        if track:Validate() then -- check since it may have been deleted already
            local child_tracks = track:Children(true)
            if #child_tracks.unused == #child_tracks then child_tracks:Delete() end
        end
    end
end)
