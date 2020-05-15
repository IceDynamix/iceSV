-- MoonSharp Documentation - http://www.moonsharp.org/getting_started.html
-- ImGui - https://github.com/ocornut/imgui
-- ImGui.NET - https://github.com/mellinoe/ImGui.NET

-- MAIN ------------------------------------------------------

function draw()
    window_svMenu()
    -- imgui.ShowDemoWindow()
    -- imgui.ShowUserGuide()
end

-- WINDOWS ----------------------------------------------------

function window_svMenu()
    statusMessage = state.GetValue("statusMessage") or "v1.0"

    imgui.Begin("SV Menu", true, imgui_window_flags.AlwaysAutoResize)

    imgui.BeginTabBar("function_selection")
    menu_information()
    menu_linearSV()
    -- menu_stutterSV()
    -- menu_cubicBezierSV()
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
        gui_tooltip("Creates an SV gradient based on two points in time")

        imgui.BulletText("Stutter SV")
        gui_tooltip("Creates a normalized stutter effect")

        imgui.Separator()

        imgui.TextWrapped("Github: https://example.com")
        gui_tooltip("I can't hyperlink stuff in a plugin, so you'll have to make do with manually copying the url :(")
        imgui.TextWrapped("Created by IceDynamix")
        imgui.TextWrapped("Heavily inspired by Evening's Reamber")
        gui_tooltip("let's be real this is basically a direct quaver port")
        imgui.EndTabItem()
    end
end


function menu_linearSV()

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

        vars = util_retrieveStateVariables(menuID, vars)

        -- Create UI Elements

        gui_title("Offset")

        vars = gui_startEndOffset(vars)

        imgui.Separator()

        gui_title("Velocities")

        _, vars["startSV"] = imgui.SliderFloat("Start Velocity", vars["startSV"], -10.0, 10.0, "%.2fx")
        gui_tooltip("Ctrl+Click on a slider to enter as text!")

        _, vars["endSV"] = imgui.SliderFloat("End Velocity", vars["endSV"], -10.0, 10.0, "%.2fx")
        gui_tooltip("Ctrl+Click on a slider to enter as text!")

        swapButton = imgui.Button("Swap start and end velocity")
        if swapButton then vars["startSV"], vars["endSV"] = vars["endSV"], vars["startSV"] end

        imgui.Separator()

        gui_title("Utilities")

        _, vars["intermediatePoints"] = imgui.InputInt("Intermediate points", vars["intermediatePoints"], 4)
        _, vars["skipEndSV"] = imgui.Checkbox("Skip end SV?", vars["skipEndSV"])

        imgui.Separator()

        if imgui.Button("Insert into map") then
            SVs = sv_linear(
                vars["startSV"],
                vars["endSV"],
                vars["startOffset"],
                vars["endOffset"],
                vars["intermediatePoints"],
                vars["skipEndSV"]
            )
            editor_placeSVs(SVs)
        end

        -- Save variables
        util_saveStateVariables(menuID, vars)

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
        -- local sv = utils.CreateScrollVelocity(offset, velocity)
        local sv = {offset=offset, velocity=velocity}
        table.insert(SVs, sv)
    end

    return SVs
end

--[[
    about beziers

    i originally planned to support any number of control points from 3 (quadratic)
    to, idk, 10 or something

    i ran into some issues when trying to write general code for all orders of n,
    which made me give up on them for now

    the way to *properly* do it
        - find length t at position x
        - use the derivative of bezier to find y at t

    problem is that i cant reliably perform the first step for any curve
    so i guess i'll be using a very bad approach to this for now... if you know more about
    this stuff please get in contact with me
]]

-- @return table of scroll velocities
function sv_cubicBezier(P1_x, P1_y, P2_x, P2_y, startOffset, endOffset, averageSV, intermediatePoints, skipEndSV)

    local stepInterval = 1/intermediatePoints
    local timeInterval = (endOffset - startOffset) * stepInterval

    -- the larger this number, the more accurate the final sv is
    -- ... and the longer it's going to take
    local totalSampleSize = intermediatePoints * 100
    local allBezierSamples = {}
    for t=0, 1, 1/totalSampleSize do
        local x = cubicBezier({0, P1_x, P2_x, 1}, t)
        local y = cubicBezier({0, P1_y, P2_y, 1}, t)
        table.insert(allBezierSamples, {x=x,y=y})
    end

    local SVs = {}
    local positions = {}

    local currentPoint = 0

    for sampleCounter = 1, totalSampleSize, 1 do
        if allBezierSamples[sampleCounter].x > currentPoint then
            table.insert(positions, allBezierSamples[sampleCounter].y)
            currentPoint = currentPoint + stepInterval
        end
    end

    for i = 1, intermediatePoints, 1 do
        local offset = (i-1) * timeInterval + startOffset
        local velocity = util_round((positions[i] - (positions[i-1] or 0)) * averageSV * intermediatePoints, 2)
        local sv = {offset=offset, velocity=velocity}
        table.insert(SVs, sv)
    end

    if skipEndSV == false then
        table.insert(SVs, {offset=endOffset, velocity=averageSV})
    end

    return SVs
end

-- MATH ----------------------------------------------------

-- Simple recursive implementation of the binomial coefficient
function binom(n, k)
    if k == 0 or k == n then return 1 end
    return binom(n-1, k-1) + binom(n-1, k)
end

-- Currently unused
function bernsteinPolynomial (i,n,t) return binom(n,i) * t^i * (1-t)^(n-i) end

-- Derivative for *any* bezier curve with at point t
-- Currently unused
function bezierDerivative(P, t)
    local n = util_tableLength(P)
    local sum = 0
    for i = 0, n-2, 1 do sum = sum + bernsteinPolynomial(i,n-2,t) * (P[i+2].y - P[i+1].y) end
    return sum
end

function cubicBezier(P, t)
    return P[1] + 3*t*(P[2]-P[1]) + 3*t^2*(P[1]+P[3]-2*P[2]) + t^3*(P[4]-P[1]+3*P[2]-3*P[3])
end

-- UTIL ---------------------------------------------------

function util_retrieveStateVariables(menuID, variables)
    for key in pairs(variables) do
        variables[key] = state.GetValue(menuID..key) or variables[key]
    end
    return variables
end

function util_saveStateVariables(menuID, variables)
    for key in pairs(variables) do
        state.SetValue(menuID..key, variables[key])
    end
end

function util_tableLength(table)
    local n = 0
    for _,_ in pairs(table) do n = n + 1 end
    return n
end

function util_displayVal(label, value)
    imgui.TextWrapped(string.format("%s: %s", label, tostring(value)))
end

function util_round(x, n) return tonumber(string.format("%." .. (n or 0) .. "f", x)) end

-- GUI ELEMENTS ----------------------------------------------------------

function gui_title(title)
    imgui.TextWrapped(string.upper(title))
end

function gui_startEndOffset(variables)
    _, variables["startOffset"] = imgui.InputInt("Start offset in ms", variables["startOffset"], 1000)
    _, variables["endOffset"] = imgui.InputInt("End offset in ms", variables["endOffset"], 1000)

    imgui.TextWrapped("Copy current timestamp to... ")

    imgui.SameLine()

    if imgui.Button("Start offset") then
        variables["startOffset"] = state.SongTime
        statusMessage = "Copied into start offset!"
    end

    imgui.SameLine()

    if imgui.Button("End offset") then
        variables["endOffset"] = state.SongTime
        statusMessage = "Copied into end offset!"
    end

    return variables
end

function gui_tooltip(text)
    if imgui.IsItemHovered() then imgui.SetTooltip(text) end
end

-- EDITOR ----------------------------------------------------------

function editor_placeSVs(SVs)
    if util_tableLength(SVs) == 0 then return end
    actions.PlaceScrollVelocityBatch(SVs)
    for _, sv in pairs(SVs) do
        print(string.format("Added SV at: %4.2fms \t| %4.2fx", sv.StartTime, sv.Multiplier))
    end
    statusMessage = "Inserted " .. util_tableLength(SVs) .. " SV points!"
end
