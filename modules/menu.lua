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

        local velocities = { vars["startSV"], vars["endSV"] }
        imgui.PushItemWidth(style.CONTENT_WIDTH)
        _, velocities = imgui.DragFloat2("Start/End Velocity", velocities, 0.01, -10.0, 10.0, "%.2fx")
        imgui.PopItemWidth()
        vars["startSV"], vars["endSV"] = table.unpack(velocities)
        gui.helpMarker("Ctrl+Click to enter as text!")

        local widths = util.calcAbsoluteWidths({0.7,0.3})

        if imgui.Button("Swap start and end velocity", {widths[1], style.DEFAULT_WIDGET_HEIGHT}) then
            vars["startSV"], vars["endSV"] = vars["endSV"], vars["startSV"]
        end

        imgui.SameLine(0, style.SAMELINE_SPACING)

        if imgui.Button("Reset", {widths[2], style.DEFAULT_WIDGET_HEIGHT}) then
            vars["startSV"] = 1
            vars["endSV"] = 1
        end

        gui.separator()

        gui.title("Utilities")

        imgui.PushItemWidth(style.CONTENT_WIDTH)
        _, vars["intermediatePoints"] = imgui.InputInt("Intermediate points", vars["intermediatePoints"], 4)
        imgui.PopItemWidth()

        vars["intermediatePoints"] = math.clamp(vars["intermediatePoints"], 1, 500)

        _, vars["skipEndSV"] = imgui.Checkbox("Skip end SV?", vars["skipEndSV"])

        gui.separator()

        gui.title("CALCULATE")

        if imgui.Button("Insert into map", {style.CONTENT_WIDTH, style.DEFAULT_WIDGET_HEIGHT}) then
            SVs = sv.linear(
                vars["startSV"],
                vars["endSV"],
                vars["startOffset"],
                vars["endOffset"],
                vars["intermediatePoints"],
                vars["skipEndSV"]
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
            lastSVs = {}
        }

        util.retrieveStateVariables(menuID, vars)

        gui.title("Note")
        gui.hyperlink("https://cubic-bezier.com/")

        gui.separator()
        gui.title("Offset")

        gui.startEndOffset(vars)

        gui.separator()
        gui.title("Values")

        imgui.PushItemWidth(style.CONTENT_WIDTH)

        local x = {vars["x1"],vars["x2"]}
        _, x = imgui.DragFloat2("x1, x2", x, 0.01, 0, 1, "%.2f")
        vars["x1"], vars["x2"] = table.unpack(x)

        local y = {vars["y1"],vars["y2"]}
        _, y = imgui.DragFloat2("y1, y2", y, 0.01, -1, 2, "%.2f")
        vars["y1"], vars["y2"] = table.unpack(y)


        _, vars["averageSV"] = imgui.DragFloat("Average SV", vars["averageSV"], 0.01, -100, 100, "%.2f")

        if imgui.Button("Reset") then
            --[[
                I tried to implement a function where it takes the default values
                but it seems that I'm unsuccessful in deep-copying the table

                Something like this:

                function util.resetToDefaultValues(currentVars, defaultVars, varsToReset)
                    for _, key in pairs(varsToReset) do
                        if currentVars[key] and defaultVars[key] then
                            currentVars[key] = defaultVars[key]
                        end
                    end
                    return currentVars
                end
            ]]

            vars["x1"] = 0.35
            vars["x2"] = 0.00
            vars["y1"] = 0.65
            vars["y2"] = 1.00
            vars["averageSV"] = 1.0
        end

        imgui.PopItemWidth()

        gui.separator()
        gui.title("Utilities")

        imgui.PushItemWidth(style.CONTENT_WIDTH)
        _, vars["intermediatePoints"] = imgui.InputInt("Intermediate points", vars["intermediatePoints"], 4)
        imgui.PopItemWidth()

        vars["intermediatePoints"] = math.clamp(vars["intermediatePoints"], 1, 500)

        _, vars["skipEndSV"] = imgui.Checkbox("Skip end SV?", vars["skipEndSV"])

        gui.separator()
        gui.title("Calculate")

        imgui.PushItemWidth(style.CONTENT_WIDTH)
        if imgui.Button("Insert into map") then
            vars["lastSVs"] = sv.cubicBezier(
                vars["x1"],
                vars["y1"],
                vars["x2"],
                vars["y2"],
                vars["startOffset"],
                vars["endOffset"],
                vars["averageSV"],
                vars["intermediatePoints"],
                vars["skipEndSV"]
            )
            editor.placeSVs(vars["lastSVs"])
        end
        imgui.PopItemWidth()

        util.saveStateVariables(menuID, vars)
    end
end
