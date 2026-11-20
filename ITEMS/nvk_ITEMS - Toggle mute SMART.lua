-- @noindex
-- SETUP --
local r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
if not functionsLoaded then
    return
end
-- SCRIPT --
local ext_str = 'nvk_TOGGLEVOL'
run(function()
    ---@param item Item
    local function mute(item)
        if not item.video or item.mute then
            item.mute = not item.mute
            return
        end
        local vol = item.vol
        if vol > 0 then
            item.vol = 0
            item:SetExtState(ext_str, vol)
        else
            item.vol = tonumber(item:GetExtState(ext_str)) or 1
        end
    end

    for _, item in ipairs(Items.Selected()) do
        mute(item)
    end
end)
