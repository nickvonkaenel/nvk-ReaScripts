-- @noindex
-- Instructions: Run this script with the subproject open to adjust settings such as tail length and split behavior.
SCRIPT_FOLDER = 'simple'
r = reaper
SEP = package.config:sub(1, 1)
DATA = _VERSION == 'Lua 5.3' and 'Data53' or 'Data'
DATA_PATH = debug.getinfo(1, 'S').source:match '@(.+[/\\])' .. DATA .. SEP
dofile(DATA_PATH .. 'functions.dat')
if not functionsLoaded then return end

bar.no_logo_text = true

---@diagnostic disable: duplicate-set-field
function Bar.LogoPopup()
    ImGui.TextWrapped(
        ctx,
        'Run this script with a subproject open in order to change the settings for that subproject next time it is updated with nvk_SUBPROJECT or one of the update scripts.'
    )
end

function SimpleDraw()
    local proj = r.EnumProjects(-1)
    if proj ~= scr.proj then
        scr.proj = proj
        scr.proj_name = r.GetProjectName(proj)
        scr.proj_name = scr.proj_name:match '(.+)%.[^%.]+$' or scr.proj_name
        LoadSubprojectSettings()
    end

    bar.hover_txt = bar.hover_txt or 'nvk_SP Settings'
    local rv
    if not config.tail then config.tail = 0 end
    local precision = config.tail < 0.1 and 3 or config.tail < 1 and 2 or 1
    local format = string.format('%%.%df', precision)
    rv, config.tail = gui.Drag(
        ctx,
        'Tail',
        config.tail,
        0,
        0,
        5,
        format .. ' seconds',
        ImGui.SliderFlags_Logarithmic | ImGui.SliderFlags_NoRoundToFormat,
        true
    )
    SUBPROJECT_TAIL = tonumber(string.format(format, config.tail))
    local w = ImGui.CalcItemWidth(ctx)
    local h = ImGui.GetFrameHeightWithSpacing(ctx) * 1.2
    if ImGui.BeginTable(ctx, 'buttons', 2, nil, w) then
        ImGui.TableSetupColumn(ctx, 'reset', ImGui.TableColumnFlags_WidthStretch)
        ImGui.TableSetupColumn(ctx, 'apply', ImGui.TableColumnFlags_WidthStretch)
        ImGui.PushFont(ctx, fonts.heading2)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 24)
        ImGui.TableNextColumn(ctx)
        if ImGui.Button(ctx, 'Cancel', -FLT_MIN, h * 1.1) then scr.exit = true end
        ImGui.TableNextColumn(ctx)
        Colors.ColoredButtonPush()
        if ImGui.Button(ctx, 'Ok', -FLT_MIN, h * 1.1) then Actions.Run() end
        Colors.ColoredButtonPop()
        ImGui.PopFont(ctx)
        ImGui.PopStyleVar(ctx)
        ImGui.EndTable(ctx)
    end
    ImGui.Spacing(ctx)
end

function SimpleRun()
    StoreSubprojectSettings()
    SubProjectMarkers()
end
