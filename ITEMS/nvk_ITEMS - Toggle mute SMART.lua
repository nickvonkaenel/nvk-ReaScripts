-- @noindex
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. DATA .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then return end
-- SCRIPT --
run(function()
    for i, item in ipairs(Items()) do
        if item.video then
            local vol = item.vol
            if vol > 0 then
                item.vol = 0
                item:SetExtState('nvk_TOGGLEVOL', vol)
            else
                item.vol = tonumber(item:GetExtState('nvk_TOGGLEVOL')) or 1
            end
        else
            item.mute = not item.mute
        end
    end
end)
