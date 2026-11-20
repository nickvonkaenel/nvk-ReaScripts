-- @noindex
-- Checks for nvk.tools updates. With automatic updates on, it installs them: at once when no nvk window is open,
-- otherwise at the next REAPER start. nvk_API runs it quietly after REAPER starts and every 12 hours, and nvk
-- windows run it when nvk_API cannot; run from the Action List, it says what it found.
--
-- It loads only the update modules, not the SHARED bootstrap: no window, no ImGui, nothing a background check does
-- not need.
local r = reaper
SEP = SEP or package.config:sub(1, 1)
local script_dir = assert(debug.getinfo(1, 'S').source:match('^@?(.*[\\/])'))
SHARED_DATA_PATH = SHARED_DATA_PATH or (script_dir .. 'Data' .. SEP)

if type(LuaFile) ~= 'table' or not LuaFile.DoFile then
    local loader_path = SHARED_DATA_PATH .. 'lua_file.lua'
    local file = io.open(loader_path, 'rb')
    if not file then
        r.MB('nvk_SHARED is incomplete. Please reinstall nvk_SHARED.', 'nvk.tools updates', 0)
        return
    end
    local bytes = file:read('a')
    file:close()
    LuaFile = assert(load(bytes, '@' .. loader_path, 'bt'))()
end

if not os_is then
    local os_name = r.GetOS():lower()
    os_is = {
        win = os_name:find('win') ~= nil,
        mac = os_name:find('osx') ~= nil or os_name:find('macos') ~= nil,
        mac_arm = os_name:find('macos') ~= nil,
        lin = os_name:find('other') ~= nil,
    }
end

local Updates = LuaFile.DoFile(SHARED_DATA_PATH .. 'update' .. SEP .. 'service.lua')
local TITLE = 'nvk.tools updates'
local background = Updates.StartedInBackground()

if Updates.Busy() then
    if not background then
        r.MB('An update check is already running.', TITLE, 0)
    end
    return
end

local mode = Updates.Mode()
if mode == 'reapack' and not background then
    -- ReaPack installs these tools here; it is what checks and updates them.
    local sync = r.NamedCommandLookup('_REAPACK_SYNC')
    if sync ~= 0 then
        r.Main_OnCommand(sync, 0)
        return
    end
end

local function plural(count, word)
    return count .. ' ' .. word .. (count == 1 and '' or 's')
end

local function report(result)
    if background then
        return
    end
    if result.mode == 'developer' then
        r.MB(
            'Automatic updates are off: this REAPER folder is a developer install (it holds an nvk_developer file).',
            TITLE,
            0
        )
    elseif result.error then
        r.MB('Could not check for updates.\n\n' .. tostring(result.error), TITLE, 0)
    elseif result.plan then
        local changed = 0
        for _, entry in pairs(result.plan.packages) do
            if entry.action ~= 'current' and entry.action ~= 'kept' then
                changed = changed + 1
            end
        end
        if result.staged then
            r.MB(
                'Downloaded updates to ' .. plural(changed, 'package') .. '. They install when REAPER restarts.',
                TITLE,
                0
            )
        else
            r.MB(
                'Updated '
                    .. plural(changed, 'package')
                    .. '.'
                    .. (result.restart and '\n\nRestart REAPER to load the new nvk_API.' or ''),
                TITLE,
                0
            )
        end
    elseif result.restart then
        r.MB('Restart REAPER to load the installed update.', TITLE, 0)
    elseif result.mode == 'automatic' then
        r.MB('Your nvk.tools installation is up to date.', TITLE, 0)
    else
        r.MB('Checked for updates. ReaPack installs them here.', TITLE, 0)
    end
end

local job = Updates.Job()
local function step()
    if job.Step() then
        report(job.result or {})
        return
    end
    r.defer(step)
end
step()
