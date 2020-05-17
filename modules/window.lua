function window.svMenu()
    statusMessage = state.GetValue("statusMessage") or "%VERSION%"

    imgui.Begin("SV Menu", true, imgui_window_flags.AlwaysAutoResize)

    imgui.BeginTabBar("function_selection")
    menu.information()
    menu.linearSV()
    -- menu.stutterSV()
    menu.cubicBezierSV()
    -- menu.editSVRange()
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
