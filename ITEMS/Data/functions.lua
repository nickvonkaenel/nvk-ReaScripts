-- SOURCE --
-- BOILERPLATE --
-- Package shim. It ships as source (the marker on line 1 tells `compile` to copy it instead of running luac):
-- only a source file can locate the repository from its own path, and only a loader that reads the file itself
-- can open compiled code from a non-ASCII Windows install path. Everything package-specific lives in
-- Data/bootstrap.lua, which this shim enters through LuaFile with this directory's absolute path. Every package's
-- Data/functions.lua is a byte-for-byte copy of this template; SHARED/tests/package_shim_test.lua checks it.
local r = reaper
function PathFix(...)
    SEP = SEP or package.config:sub(1, 1)
    local path = table.concat({ ... }, SEP)
    path = path:gsub('[\\/]+', SEP)
    return path
end

local bootstrap_data_path = assert(debug.getinfo(1, 'S').source:match('^@?(.*[\\/])[^\\/]-$'))
local repository_path = bootstrap_data_path:match('^(.*[\\/])[^\\/]+[\\/]Data[\\/]$')
if not repository_path then
    r.MB('Could not determine the nvk-ReaScripts repository path from:\n' .. bootstrap_data_path, 'Error', 0)
    return
end
SHARED_DATA_PATH = PathFix(repository_path, 'SHARED', 'Data') .. SEP
if not r.file_exists(SHARED_DATA_PATH .. 'basics.lua') then
    if r.ReaPack_BrowsePackages then
        r.MB('nvk_SHARED is required to run this script. Please install it from ReaPack', 'Error', 0)
        r.ReaPack_BrowsePackages('nvk_SHARED')
    else
        r.MB('nvk_SHARED is required to run this script. Download and run the installer from nvk.tools.', 'Error', 0)
    end
    return
end

-- Seeds the global LuaFile loader from SHARED by reading the file directly, because the stock loader cannot open
-- compiled code on a non-ASCII Windows path. An existing table is reused, so nested bootstraps (TAKES entering
-- FOLDER_ITEMS, then SHARED) share one loader and one execution-path stack. basics.lua carries the same seed for
-- consumers that still enter SHARED directly.
local function seed_lua_file(shared_data_path)
    if type(LuaFile) == 'table' and LuaFile.API then
        return LuaFile
    end
    local loader_path = shared_data_path .. 'lua_file.lua'
    local file, open_error = io.open(loader_path, 'rb')
    if not file then
        return nil, 'cannot open ' .. tostring(open_error)
    end
    local bytes = file:read('a')
    file:close()
    if not bytes then
        return nil, 'cannot read ' .. loader_path
    end
    local chunk, load_error = load(bytes, '@' .. loader_path, 'bt')
    if not chunk then
        return nil, load_error
    end
    local loader = chunk()
    if type(loader) ~= 'table' or type(loader.DoFile) ~= 'function' then
        return nil, loader_path .. ' did not return the loader table'
    end
    LuaFile = loader
    return loader
end

local REQUIRED_LUA_FILE_API = 2
local loader, loader_error = seed_lua_file(SHARED_DATA_PATH)
if not loader or (loader.API or 0) < REQUIRED_LUA_FILE_API then
    r.MB(
        'nvk_SHARED is outdated or incomplete. Please update it'
            .. (r.ReaPack_BrowsePackages and ' from ReaPack.' or ' with the nvk.tools Installer.')
            .. (loader_error and ('\n\n' .. loader_error) or ''),
        'Error',
        0
    )
    if r.ReaPack_BrowsePackages then
        r.ReaPack_BrowsePackages('nvk_SHARED')
    end
    return
end
-- END SEED --

LuaFile.DoFile(bootstrap_data_path .. 'bootstrap.lua')(bootstrap_data_path)
