-- @noindex
-- This script runs the startup actions you set up in the nvk_SHARED - Startup Actions.lua script.
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')

local cfg = scr.path:match '(.+) %- Run%.lua$' .. '_cfg'
if not pcall(doFile, cfg) or not config then return end

for i, action in ipairs(config.user_actions) do
    if config.user_actions[action] then
        local action_id = tonumber(action) or r.NamedCommandLookup(action)
        if action_id then r.Main_OnCommand(action_id, 0) end
    end
end

if config.default_actions then
    for action, enabled in pairs(config.default_actions) do
        if enabled then
            local action_id = tonumber(action) or r.NamedCommandLookup(action)
            if action_id then r.Main_OnCommand(action_id, 0) end
        end
    end
end
