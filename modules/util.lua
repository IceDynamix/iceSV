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

function util.printTable(table)
    util.toString(table, true)
    if table then
        imgui.Columns(2)
        imgui.Text("Key");   imgui.NextColumn();
        imgui.Text("Value"); imgui.NextColumn();
        imgui.Separator()
        for key, value in pairs(table) do
            util.toString(key, true)   imgui.NextColumn();
            util.toString(value, true) imgui.NextColumn();
        end
        imgui.Columns(1)
    end
end

function util.toString(var, imguiText)
    local string = ""

    if var == nil then string = "<null>"
    elseif type(var) == "table" then string = "<table.length=".. #var ..">"
    elseif var == "" then string = "<empty string>"
    else string = "<" .. type(var) .. "=" .. var .. ">" end

    if imguiText then imgui.Text(string) end
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

function util.subdivideTable(oldTable, nKeep, nRemove, keepStartAndEnd)
    local newTable = {}

    if keepStartAndEnd then table.insert(newTable, oldTable[1]) end

    for i, value in pairs(oldTable) do
        if i % (nKeep + nRemove) < nKeep then
            table.insert(newTable, value)
        end
    end

    if keepStartAndEnd then table.insert(newTable, oldTable[#oldTable]) end

    return newTable
end

function util.mapFunctionToTable(oldTable, func, params)
    local newTable = {}
    for _, value in pairs(oldTable) do
        if params then
            table.insert(newTable, func(value, table.unpack(params)))
        else
            table.insert(newTable, func(value))
        end
    end
    return newTable
end
