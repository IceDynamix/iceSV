function menu.information()
    if imgui.BeginTabItem("Information") then
        gui.title("Help")

        imgui.TextWrapped("Hover over each function for an explanation")

        imgui.BulletText("Linear SV")
        gui.tooltip("Creates an SV gradient based on two points in time")

        imgui.BulletText("Stutter SV")
        gui.tooltip("Creates a normalized stutter effect")

        gui.separator()
        gui.title("About")

        gui.hyperlink("https://github.com/IceDynamix/IceSV", "Github")
        imgui.TextWrapped("Created by IceDynamix")
        imgui.TextWrapped("Heavily inspired by Evening's re:amber")
        gui.tooltip("let's be real this is basically a direct quaver port")
        imgui.EndTabItem()
    end
end

function menu.linearSV()

    local menuID = "linear"

    if imgui.BeginTabItem("Linear SV") then

        -- Initialize variables
        local vars = {
            startSV = 1,
            endSV = 1,
            intermediatePoints = 16,
            startOffset = 0,
            endOffset = 0,
            skipEndSV = false
        }

        util.retrieveStateVariables(menuID, vars)

        -- Create UI Elements

        gui.title("Offset")
        gui.startEndOffset(vars)

        gui.separator()
        gui.title("Velocities")

        local velocities = { vars.startSV, vars.endSV }
        imgui.PushItemWidth(style.CONTENT_WIDTH)
        _, velocities = imgui.DragFloat2("Start/End Velocity", velocities, 0.01, -10.0, 10.0, "%.2fx")
        imgui.PopItemWidth()
        vars.startSV, vars.endSV = table.unpack(velocities)
        gui.helpMarker("Ctrl+Click to enter as text!")

        local widths = util.calcAbsoluteWidths({0.7,0.3})

        if imgui.Button("Swap start and end velocity", {widths[1], style.DEFAULT_WIDGET_HEIGHT}) then
            vars.startSV, vars.endSV = vars.endSV, vars.startSV
        end

        imgui.SameLine(0, style.SAMELINE_SPACING)

        if imgui.Button("Reset", {widths[2], style.DEFAULT_WIDGET_HEIGHT}) then
            vars.startSV = 1
            vars.endSV = 1
        end

        gui.separator()
        gui.title("Utilities")

        gui.intermediatePoints(vars)

        gui.separator()
        gui.title("CALCULATE")

        if imgui.Button("Insert into map", {style.CONTENT_WIDTH, style.DEFAULT_WIDGET_HEIGHT}) then
            SVs = sv.linear(
                vars.startSV,
                vars.endSV,
                vars.startOffset,
                vars.endOffset,
                vars.intermediatePoints,
                vars.skipEndSV
            )
            editor.placeSVs(SVs)
        end

        -- Save variables
        util.saveStateVariables(menuID, vars)

        imgui.EndTabItem()
    end
end

function menu.cubicBezierSV()

    local menuID = "cubicBezier"

    if imgui.BeginTabItem("Cubic Bezier") then

        local vars = {
            startOffset = 0,
            endOffset = 0,
            x1 = 0.35,
            y1 = 0.00,
            x2 = 0.65,
            y2 = 1.00,
            averageSV = 1.0,
            intermediatePoints = 16,
            skipEndSV = false,
            lastSVs = {},
            lastPositionValues = {},
            stringInput = "cubic-bezier(.35,.0,.65,1)"
        }

        local xBounds = { 0.0, 1.0}
        local yBounds = {-1.0, 2.0}

        util.retrieveStateVariables(menuID, vars)

        gui.title("Note")
        gui.hyperlink("https://cubic-bezier.com/")

        gui.separator()
        gui.title("Offset")

        gui.startEndOffset(vars)

        gui.separator()
        gui.title("Values")

        local widths = util.calcAbsoluteWidths(style.BUTTON_WIDGET_RATIOS)

        if imgui.Button("Parse", {widths[1], style.DEFAULT_WIDGET_HEIGHT}) then
            local regex = "(-?%d*%.?%d+)"
            captures = {}
            for capture, _ in string.gmatch(vars.stringInput, regex) do
                statusMessage = statusMessage .. "," .. capture
                table.insert(captures, tonumber(capture))
            end
            if #captures >= 4 then
                vars.x1, vars.y1, vars.x2, vars.y2  = table.unpack(captures)
                statusMessage = "Copied values"
            else
                statusMessage = "Invalid string"
            end
        end

        imgui.SameLine(0, style.SAMELINE_SPACING)

        imgui.PushItemWidth(widths[2])
        _, vars.stringInput = imgui.InputText("String", vars.stringInput, 50, 4112)
        imgui.PopItemWidth()

        imgui.SameLine()
        imgui.TextDisabled("(?)")
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.TextWrapped("Examples:")
            gui.bulletList({
                "cubic-bezier(.35,.0,.65,1)",
                ".17,.67,.83,.67",
                "https://cubic-bezier.com/#.76,-0.17,.63,1.35"
            })
            imgui.TextWrapped("Or anything else that has 4 numbers")
            imgui.EndTooltip()
        end

        imgui.PushItemWidth(style.CONTENT_WIDTH)

        local coords = {}
        _, coords = imgui.DragFloat4("x1, y1, x2, y2", {vars.x1, vars.y1, vars.x2, vars.y2}, 0.01, -5, 5, "%.2f")
        vars.y2, vars.x1, vars.y1, vars.x2 = table.unpack(coords) -- the coords returned are in this order for some stupid reason??
        imgui.PopItemWidth()

        gui.helpMarker("x: 0.0-1.0\ny: -1.0-2.0")

        -- Set limits here instead of in the DragFloat4, since this also covers the parsed string
        vars.x1, vars.x2 = table.unpack(util.mapFunctionToTable({vars.x1, vars.x2}, math.clamp, xBounds))
        vars.y1, vars.y2 = table.unpack(util.mapFunctionToTable({vars.y1, vars.y2}, math.clamp, yBounds))

        imgui.Dummy({0,10})

        gui.averageSV(vars, widths)

        gui.separator()
        gui.title("Utilities")

        gui.intermediatePoints(vars)

        gui.separator()
        gui.title("Calculate")

        if imgui.Button("Insert into map ", {style.CONTENT_WIDTH, style.DEFAULT_WIDGET_HEIGHT}) then
            statusMessage = "pressed"
            vars.lastSVs, vars.lastPositionValues = sv.cubicBezier(
                vars.x1,
                vars.y1,
                vars.x2,
                vars.y2,
                vars.startOffset,
                vars.endOffset,
                vars.averageSV,
                vars.intermediatePoints,
                vars.skipEndSV
            )

            editor.placeSVs(vars.lastSVs)
        end

        if vars.lastSVs then
            gui.separator()
            gui.title("Plots")
            gui.plot(vars.lastPositionValues, "Position Data", "y")
            gui.plot(vars.lastSVs, "Velocity Data", "Multiplier")
        end

        util.saveStateVariables(menuID, vars)

        imgui.EndTabItem()
    end
end
