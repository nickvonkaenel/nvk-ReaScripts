-- @noindex
-- If you have no items selected, toggles the width envelope of selected tracks. With items selected will add/remove the effect you set below to the active take. This will be overriden if you use the script 'nvk_TAKES - Toggle width fx - save last touched parameter as script setting' which will save an fx/parameter which will override what is set here.
-- USER CONFIG --
FX_NAME = 'Ozone Imager'
FX_PARAM = 'Width'
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    local setting_str = 'nvk_TAKES - WidthFX'
    local paramNum
    if r.HasExtState(setting_str, 'fxName') and r.HasExtState(setting_str, 'param') then
        paramNum = tonumber(r.GetExtState(setting_str, 'param'))
        if paramNum then FX_NAME = r.GetExtState(setting_str, 'fxName') end
    end
    local itemCount = r.CountSelectedMediaItems(0)
    local tracks = SaveSelectedTracks()
    if itemCount > 0 then
        if itemCount > 6 then
            if r.MB('Add FX to ' .. itemCount .. ' takes?', scr.name, 1) ~= 1 then return end
        end
        for i = 0, itemCount - 1 do
            local item = r.GetSelectedMediaItem(0, i)
            local take = r.GetActiveTake(item)
            if take then
                local fxadded, fx = AddTakeFxByName(take, FX_NAME)
                if not fx then return end
                if fxadded then
                    if paramNum then
                        r.TakeFX_GetEnvelope(take, fx, paramNum, true)
                    else
                        GetTakeFXParamByName(take, fx, FX_PARAM, true)
                    end
                else
                    r.TakeFX_Delete(take, fx)
                end
            end
        end
    else
        for i, track in ipairs(tracks) do
            r.SetOnlyTrackSelected(track)
            local br_env = r.GetTrackEnvelopeByName(track, 'Width')
            if br_env ~= nil then
                local width_env = r.BR_EnvAlloc(br_env, false)
                if select(2, r.BR_EnvGetProperties(width_env)) then -- if visible
                    r.Main_OnCommand(41870, 0) -- select width envelope
                    r.UpdateArrange()
                    r.PreventUIRefresh(-1)
                    r.Main_OnCommand(40065, 0) -- clear envelope
                    r.PreventUIRefresh(1)
                else
                    r.Main_OnCommand(41870, 0) -- select width envelope
                end
            else
                r.Main_OnCommand(41870, 0) -- select width envelope
            end
        end
    end
    RestoreSelectedTracks(tracks)
end)
