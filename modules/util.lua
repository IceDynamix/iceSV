function util.retrieveStateVariables(menuID, variables)
    for key in pairs(variables) do
        variables[key] = state.GetValue(menuID..key) or variables[key]
    end
end

function util.saveStateVariables(menuID, variables)
    for key in pairs(variables) do
        state.SetValue(menuID..key, variables[key])
    end
end

function util.displayVal(label, value)
    imgui.TextWrapped(string.format("%s: %s", label, tostring(value)))
end

function util.toString(var)
    local string = ""
    string = var or "<null>"
    if type(var) == "table" then string = "<list.length=".. #var ..">" end
    if var == "" then string = "<empty string>" end
    return string
end

function util.calcAbsoluteWidths(relativeWidths)
    local absoluteWidths = {}
    local n = #relativeWidths
    for _, value in pairs(relativeWidths) do
        table.insert(absoluteWidths, (value * style.CONTENT_WIDTH) - (style.SAMELINE_SPACING/n))
    end
    return absoluteWidths
end
