-- MoonSharp Documentation - http://www.moonsharp.org/getting_started.html
-- ImGui - https://github.com/ocornut/imgui
-- ImGui.NET - https://github.com/mellinoe/ImGui.NET

-- MAIN ------------------------------------------------------

function draw()
    window_svMenu()
    imgui.ShowDemoWindow()
    -- imgui.ShowUserGuide()
end

-- WINDOWS ----------------------------------------------------

function window_svMenu()
    statusMessage = util_getValue("statusMessage", "")

    imgui.Begin("SV Menu", true, imgui_window_flags.AlwaysAutoResize)

    imgui.BeginTabBar("function_selection")
    menu_information()
    menu_linearSV()
    -- menu_stutterSV()
    -- menu_bezierSV()
    -- menu_copySV()
    -- menu_BpmGradient()
    imgui.EndTabBar()

    imgui.Separator()
    imgui.TextWrapped(statusMessage)

    -- This line needs to be added, so that the UI under it in-game
    -- is not able to be clicked. If you have multiple windows, you'll want to check if
    -- either one is hovered.
    state.IsWindowHovered = imgui.IsWindowHovered()
    imgui.End()

    state.SetValue("statusMessage", statusMessage)
end

-- MENUS -------------------------------------------------------

function menu_information()
    if imgui.BeginTabItem("Information") then
        imgui.TextWrapped("Hover over each function for an explanation")

        imgui.BulletText("Linear SV")
        if imgui.IsItemHovered() then imgui.SetTooltip("Creates an SV gradient based on two points in time") end

        imgui.BulletText("Stutter SV")
        if imgui.IsItemHovered() then imgui.SetTooltip("Creates a normalized stutter effect") end

        imgui.Separator()

        imgui.TextWrapped("Github: https://example.com")
        if imgui.IsItemHovered() then imgui.SetTooltip("I can't hyperlink stuff in a plugin, so you'll have to make do with manually copying the url :(") end
        imgui.TextWrapped("Created by IceDynamix")
        imgui.TextWrapped("Heavily inspired by Evening's Reamber")
        if imgui.IsItemHovered() then imgui.SetTooltip("let's be real this is basically a direct quaver port") end
        imgui.EndTabItem()
    end
end


function menu_linearSV()
    if imgui.BeginTabItem("Linear SV") then
        -- Initialize variables

        local linear_startSV = util_getValue("linear_startSV", 1)
        local linear_endSV = util_getValue("linear_endSV", 1)
        local linear_intermediatePoints = util_getValue("linear_intermediatePoints", 16)
        local linear_startOffset = util_getValue("linear_startOffset", 0)
        local linear_endOffset = util_getValue("linear_endOffset", 0)
        local linear_skipEndSV = util_getValue("linear_skipEndSV", false)

        -- Create UI Elements

        imgui.TextWrapped("OFFSET")

        _, linear_startOffset = imgui.InputInt("Start offset in ms", linear_startOffset, 1000)
        _, linear_endOffset = imgui.InputInt("End offset in ms", linear_endOffset, 1000)

        imgui.TextWrapped("Copy current timestamp to... ")

        imgui.SameLine()

        if imgui.Button("Start offset") then
            linear_startOffset = state.SongTime
            statusMessage = "Copied into start offset!"
        end

        imgui.SameLine()

        if imgui.Button("End offset") then
            linear_endOffset = state.SongTime
            statusMessage = "Copied into end offset!"
        end

        imgui.Separator()

        imgui.TextWrapped("VELOCITIES")

        _, linear_startSV = imgui.SliderFloat("Start Velocity", linear_startSV, -10.0, 10.0, "%.2fx")
        if imgui.IsItemHovered() then imgui.SetTooltip("Ctrl+Click on a slider to enter as text!") end

        _, linear_endSV = imgui.SliderFloat("End Velocity", linear_endSV, -10.0, 10.0, "%.2fx")
        if imgui.IsItemHovered() then imgui.SetTooltip("Ctrl+Click on a slider to enter as text!") end

        swapButton = imgui.Button("Swap start and end velocity")
        if swapButton then linear_startSV, linear_endSV = linear_endSV, linear_startSV end

        imgui.Separator()

        imgui.TextWrapped("UTILITIES")

        _, linear_intermediatePoints = imgui.InputInt("Intermediate points", linear_intermediatePoints, 4)
        _, linear_skipEndSV = imgui.Checkbox("Skip end SV?", linear_skipEndSV)

        imgui.Separator()

        if imgui.Button("Insert into map") then
            SVs = sv_linear(
                linear_startSV,
                linear_endSV,
                linear_startOffset,
                linear_endOffset,
                linear_intermediatePoints,
                linear_skipEndSV
            )
            editor_placeSVs(SVs)
            statusMessage = "Inserted " .. util_tableLength(SVs) .. " SV points!"
        end

        -- Save variables

        state.SetValue("linear_startSV", linear_startSV)
        state.SetValue("linear_endSV", linear_endSV)
        state.SetValue("linear_intermediatePoints", linear_intermediatePoints)
        state.SetValue("linear_startOffset", linear_startOffset)
        state.SetValue("linear_endOffset", linear_endOffset)
        state.SetValue("linear_skipEndSV", linear_skipEndSV)

        imgui.EndTabItem()
    end


end

-- SV ---------------------------------------------------

-- Returns a list of SV objects as defined in Quaver.API/Maps/Structures/SliderVelocityInfo.cs
function sv_linear(startSV, endSV, startOffset, endOffset, intermediatePoints, skipEndSV)

    local timeInterval = (endOffset - startOffset)/intermediatePoints
    local velocityInterval = (endSV - startSV)/intermediatePoints

    if skipEndSV then intermediatePoints = intermediatePoints - 1 end

    local SVs = {}

    for step = 0, intermediatePoints, 1 do
        local offset = step * timeInterval + startOffset
        local velocity = step * velocityInterval + startSV
        local sv = utils.CreateScrollVelocity(offset, velocity)
        table.insert(SVs, sv)
    end

    return SVs
end

-- UTIL ---------------------------------------------------

function util_getValue(label, defaultValue)
    return state.GetValue(label) or defaultValue
end

function util_tableLength(table)
    local n = 0
    for _,_ in pairs(table) do n = n + 1 end
    return n
end

function util_displayVal(label, value)
    imgui.TextWrapped(string.format("%s: %s", label, tostring(value)))
end

-- EDITOR ----------------------------------------------------------

function editor_placeSVs(SVs)
    if util_tableLength(SVs) == 0 then return end
    actions.PlaceScrollVelocityBatch(SVs)
    for _, sv in pairs(SVs) do
        print(string.format("Added SV at: %4.2fms \t| %4.2fx", sv.StartTime, sv.Multiplier))
    end
end
