-- @noindex
SCRIPT_FOLDER = 'manager'
r = reaper
SEP = package.config:sub(1, 1)
-- An earlier SHARED registered this action through `Data/../`, and that entry stays in the action list. The package
-- shim needs the real folder above `Data`, so that path is collapsed here.
DATA_PATH = debug.getinfo(1, 'S').source:match('@(.+[/\\])'):gsub('[/\\]Data[/\\]%.%.([/\\])$', '%1') .. 'Data' .. SEP
dofile(DATA_PATH .. 'functions.lua')
