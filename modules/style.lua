style.SAMELINE_SPACING = 4
style.CONTENT_WIDTH = 250
style.DEFAULT_WIDGET_HEIGHT = 26
style.HYPERLINK_COLOR = { 0.53, 0.66, 0.96, 1.00 }
style.BUTTON_WIDGET_RATIOS = { 0.3, 0.7 }

function style.applyStyle()

    -- COLORS

    imgui.PushStyleColor(   imgui_col.WindowBg,                { 0.11, 0.11 ,0.11, 1.00 })
    imgui.PushStyleColor(   imgui_col.FrameBg,                 { 0.20, 0.29 ,0.42, 0.59 })
    imgui.PushStyleColor(   imgui_col.FrameBgHovered,          { 0.35, 0.51 ,0.74, 0.78 })
    imgui.PushStyleColor(   imgui_col.FrameBgActive,           { 0.17, 0.27 ,0.39, 0.67 })
    imgui.PushStyleColor(   imgui_col.TitleBg,                 { 0.11, 0.11 ,0.11, 1.00 })
    imgui.PushStyleColor(   imgui_col.TitleBgActive,           { 0.19, 0.21 ,0.23, 1.00 })
    imgui.PushStyleColor(   imgui_col.TitleBgCollapsed,        { 0.20, 0.25 ,0.30, 1.00 })
    imgui.PushStyleColor(   imgui_col.ScrollbarGrab,           { 0.44, 0.44 ,0.44, 1.00 })
    imgui.PushStyleColor(   imgui_col.ScrollbarGrabHovered,    { 0.75, 0.73 ,0.73, 1.00 })
    imgui.PushStyleColor(   imgui_col.ScrollbarGrabActive,     { 0.99, 0.99 ,0.99, 1.00 })
    imgui.PushStyleColor(   imgui_col.CheckMark,               { 1.00, 1.00 ,1.00, 1.00 })
    imgui.PushStyleColor(   imgui_col.Button,                  { 0.57, 0.79 ,0.84, 0.40 })
    imgui.PushStyleColor(   imgui_col.ButtonHovered,           { 0.40, 0.62 ,0.64, 1.00 })
    imgui.PushStyleColor(   imgui_col.ButtonActive,            { 0.24, 0.74 ,0.76, 1.00 })
    imgui.PushStyleColor(   imgui_col.Tab,                     { 0.30, 0.33 ,0.38, 0.86 })
    imgui.PushStyleColor(   imgui_col.TabHovered,              { 0.67, 0.71 ,0.75, 0.80 })
    imgui.PushStyleColor(   imgui_col.TabActive,               { 0.39, 0.65 ,0.74, 1.00 })

    -- VALUES

    -- Will make a PR soon to have this ImGui enum accessible
    local imgui_style_var = {
        Alpha = 0,
        WindowPadding = 1,
        WindowRounding = 2,
        WindowBorderSize = 3,
        WindowMinSize = 4,
        WindowTitleAlign = 5,
        ChildRounding = 6,
        ChildBorderSize = 7,
        PopupRounding = 8,
        PopupBorderSize = 9,
        FramePadding = 10,
        FrameRounding = 11,
        FrameBorderSize = 12,
        ItemSpacing = 13,
        ItemInnerSpacing = 14,
        IndentSpacing = 15,
        ScrollbarSize = 16,
        ScrollbarRounding = 17,
        GrabMinSize = 18,
        GrabRounding = 19,
        TabRounding = 20,
        ButtonTextAlign = 21,
        COUNT = 22
    }

    local rounding = 0

    imgui.PushStyleVar( imgui_style_var.WindowPadding,      { 20, 10 } )
    imgui.PushStyleVar( imgui_style_var.FramePadding,       {  9,  6 } )
    imgui.PushStyleVar( imgui_style_var.ItemSpacing,        { style.DEFAULT_WIDGET_HEIGHT/2 - 1,  4 } )
    imgui.PushStyleVar( imgui_style_var.ItemInnerSpacing,   { style.SAMELINE_SPACING, 6 } )
    imgui.PushStyleVar( imgui_style_var.ScrollbarSize,      10         )
    imgui.PushStyleVar( imgui_style_var.WindowBorderSize,   0          )
    imgui.PushStyleVar( imgui_style_var.WindowRounding,     rounding   )
    imgui.PushStyleVar( imgui_style_var.ChildRounding,      rounding   )
    imgui.PushStyleVar( imgui_style_var.FrameRounding,      rounding   )
    imgui.PushStyleVar( imgui_style_var.ScrollbarRounding,  rounding   )
    imgui.PushStyleVar( imgui_style_var.TabRounding,        rounding   )
end
