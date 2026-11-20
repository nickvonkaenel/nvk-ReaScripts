-- @noindex
-- Keeps this computer's nvk activations current with no window: refreshes them when due and moves license keys from
-- older script versions over. nvk actions start it when that work is waiting, since an action finishes before a
-- request could; it exits within a few seconds of having nothing left to do. Running it by hand is harmless.
r = reaper
SEP = package.config:sub(1, 1)
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])'):gsub('[/\\]Data[/\\]%.%.([/\\])$', '%1') .. 'Data' .. SEP
-- Started again while it runs (two actions in the same moment): replace the running copy without asking.
if r.set_action_options then
    r.set_action_options(1 | 2)
end
dofile(DATA_PATH .. 'functions.lua')
if not SHARED_DATA_PATH or not LuaFile then
    return
end

local Access = LuaFile.DoFile(SHARED_DATA_PATH .. 'runtime_access.lua')
local Upkeep = LuaFile.DoFile(SHARED_DATA_PATH .. 'runtime_upkeep.lua')
local accesses = {}
for _, product in ipairs(Access.Products.ORDER) do
    if not Access.Products[product].free then
        accesses[#accesses + 1] = Access.new { product = product }
    end
end
local job = Upkeep.Job { license2 = License2, accesses = accesses, now = r.time_precise }
local function step()
    if not job.Step() then
        r.defer(step)
    end
end
step()
