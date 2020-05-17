function gui.title(title)
    imgui.Dummy({0,5})
    imgui.Text(string.upper(title))
    imgui.Dummy({0,5})
end

function gui.separator()
    imgui.Dummy({0,5})
    imgui.Separator()
end

function gui.tooltip(text)
    if imgui.IsItemHovered() then imgui.SetTooltip(text) end
end

function gui.helpMarker(text)
    imgui.SameLine()
    imgui.TextDisabled("(?)")
    gui.tooltip(text)
end

function gui.startEndOffset(variables)

    local widths = util.calcAbsoluteWidths({ 0.3, 0.7 })

    -- ROW 1

    if imgui.Button("Current", {widths[1], style.DEFAULT_WIDGET_HEIGHT}) then
        variables["startOffset"] = state.SongTime
        statusMessage = "Copied into start offset!"
    end

    gui.tooltip("Copies the current editor position into the start offset")

    imgui.SameLine(0, style.SAMELINE_SPACING)

    imgui.PushItemWidth(widths[2])
    _, variables["startOffset"] = imgui.InputInt("Start offset in ms", variables["startOffset"], 1000)
    imgui.PopItemWidth()

    -- ROW 2

    if imgui.Button(" Current ", {widths[1], style.DEFAULT_WIDGET_HEIGHT}) then
        variables["endOffset"] = state.SongTime
        statusMessage = "Copied into end offset!"
    end

    gui.tooltip("Copies the current editor position into the end offset")

    imgui.SameLine(0, style.SAMELINE_SPACING)

    imgui.PushItemWidth(widths[2])
    _, variables["endOffset"] = imgui.InputInt("End offset in ms", variables["endOffset"], 1000)
    imgui.PopItemWidth()
end

function gui.printVars(vars, title)
    if imgui.CollapsingHeader(title, imgui_tree_node_flags.DefaultOpen) then
        imgui.Columns(3)
        gui.separator()

        imgui.Text("var");      imgui.NextColumn();
        imgui.Text("type");     imgui.NextColumn();
        imgui.Text("value");    imgui.NextColumn();

        gui.separator()

        if vars == state then
            local varList = { "DeltaTime", "UnixTime", "IsWindowHovered", "Values", "SongTime", "SelectedHitObjects", "CurrentTimingPoint" }
            for _, value in pairs(varList) do
                util.toString(value);               imgui.NextColumn();
                util.toString(type(vars[value]));   imgui.NextColumn();
                util.toString(vars[value]);         imgui.NextColumn();
            end
        else
            for key, value in pairs(vars) do
                util.toString(key);             imgui.NextColumn();
                util.toString(type(value));     imgui.NextColumn();
                util.toString(value);           imgui.NextColumn();
            end
        end

        imgui.Columns(1)
        gui.separator()
    end
end

-- Plots will come once Quaver#1985 is merged
function gui.svPlot(SVs)
    local velocities = {}
    for _, SV in pairs(SVs) do
        table.insert(velocities, SV.velocity)
    end
    imgui.PlotLines("SV Plot", velocities, #velocities)
end

-- Hyperlinks will word once Quaver#1986 is merged
function gui.hyperlink(url, text)
    local hyperlinkColor = { 0.53, 0.66, 0.96, 1.00 }

    if text then
        imgui.TextColored(hyperlinkColor, text)
    else
        imgui.TextColored(hyperlinkColor, url)
    end

    if imgui.IsItemHovered() then
        if text then imgui.SetTooltip(url) end
    end
end
