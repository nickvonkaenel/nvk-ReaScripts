-- @noindex
-- USER CONFIG --
-- SETUP --
local r = reaper
scr = {}
SEP = package.config:sub(1, 1)
local info = debug.getinfo(1, 'S')
scr.path, scr.name = info.source:match [[^@?(.*[\/])(.*)%.lua$]]
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = scr.path .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
function Main()
    local track = r.GetMasterTrack(0)
    local channels = math.floor(r.GetMediaTrackInfo_Value(track, 'I_NCHAN'))
    local retval, retvals_csv = r.GetUserInputs('Set Master Track Channel Count', 1, 'Channels', tostring(channels))
    local num = tonumber(retvals_csv)
    if retval and num then
        channels = math.floor(num)
        if channels % 2 == 0 and channels > 0 then
            r.SetMediaTrackInfo_Value(track, 'I_NCHAN', channels)
            local hwOutputs = 0
            if channels ~= 2 then hwOutputs = channels * 512 end
            r.SetTrackSendInfo_Value(track, 1, 0, 'I_SRCCHAN', hwOutputs)
        end
    end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
Main()
r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr.name, -1)
