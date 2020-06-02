function window.svMenu()
    statusMessage = state.GetValue("statusMessage") or "%VERSION%"

    imgui.Begin("SV Menu", true, imgui_window_flags.AlwaysAutoResize)

    imgui.BeginTabBar("function_selection")
    menu.information()
    menu.linearSV()
    menu.stutterSV()
    menu.cubicBezierSV()
    menu.rangeEditor()
    -- menu.BpmGradient()
    imgui.EndTabBar()

    gui.separator()
    imgui.TextDisabled(statusMessage)

    -- This line needs to be added, so that the UI under it in-game
    -- is not able to be clicked. If you have multiple windows, you'll want to check if
    -- either one is hovered.
    state.IsWindowHovered = imgui.IsWindowHovered()
    imgui.End()

    state.SetValue("statusMessage", statusMessage)
end

function window.selectedRange(vars)
    imgui.SetNextWindowSize({100 * #editor.typeAttributes[vars.type], 500})

    imgui.Begin("Selected elements", true, imgui_window_flags.AlwaysAutoResize)
        if imgui.Button("Close Window") then
            vars.windowSelectedOpen = false
        end
        imgui.Columns(#editor.typeAttributes[vars.type])

        for _, value in pairs(editor.typeAttributes[vars.type]) do
            imgui.Text(value)
            imgui.NextColumn()
        end
        imgui.Separator()

        for _, element in pairs(vars.selections[vars.type]) do
            for _, attribute in pairs(editor.typeAttributes[vars.type]) do

                -- TODO: Implememt selection select (as stupid as it sounds)
                local value = element[attribute] or "null"
                local string = "null"

                if type(value) == "number" then
                    string = string.gsub(string.format("%.2f", value), "%.00", "", 1)

                elseif value then -- not nil
                    string = "userdata"

                end

                imgui.Text(string)
                imgui.NextColumn()
            end
        end

        imgui.Columns(1)
        state.IsWindowHovered = imgui.IsWindowHovered()
    imgui.End()
end
