-- MoonSharp Documentation - http://www.moonsharp.org/getting_started.html
-- ImGui - https://github.com/ocornut/imgui
-- ImGui.NET - https://github.com/mellinoe/ImGui.NET

-- MAIN ------------------------------------------------------

function draw()
    imgui.ShowDemoWindow()
    style.applyStyle()
    window.svMenu()
end
