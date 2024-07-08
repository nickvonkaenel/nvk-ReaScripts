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
    for i, item in ipairs(Items()) do
        local track = item.track
        if track.tcph >= 5 then
            local num = track.num
            while num > 1 do
                num = num - 1
                local newTrack = Track(num)
                assert(newTrack, 'newTrack is nil')
                if newTrack.tcph >= 5 then
                    item.track = newTrack
                    break
                end
            end
        end
    end
end)
