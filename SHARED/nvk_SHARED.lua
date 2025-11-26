--[[
Description: nvk_SHARED
Version: 4.3.0
About:
    # nvk_SHARED

    nvk_SHARED is a common library for all scripts in the nvk-ReaScripts repository. It contains functions and data that are used by multiple scripts and is required to run them.
Author: nvk
Links:
    Website https://nvk.tools
Changelog:
    4.3.0
        Improve behavior when nvk_SEARCH is set to always on top and a project is loaded with prompts in the same location as the script. Not completely fixed, recommend not using 'Always on Top' if possible
    4.2.0
        Minor visual improvements
        Can now reset style sliders to default value with right-click
    4.0.0
        Support for new take detection behavior and scripts
        Codebase refactoring - make sure to update all your scripts to the latest version
        Various minor improvements and bug fixes
        Support for latest version of ReaImGui, font improvements
        Script unfocused color improvements, a little bit more clear when script does not have focus
    For full changelog, visit https://nvk.tools/docs/shared#changelog
Provides:
    Data/**/*.lua
    **/*.otf
    [main] *.lua
--]]
