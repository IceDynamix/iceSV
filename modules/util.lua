function util.retrieveStateVariables(menuID, variables)
    for key, value in pairs(variables) do
        variables[key] = state.GetValue(menuID..key) or value
    end
end

function util.saveStateVariables(menuID, variables)
    for key, value in pairs(variables) do
        state.SetValue(menuID..key, value)
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
            util.toString(key, true);   imgui.NextColumn();
            util.toString(value, true); imgui.NextColumn();
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

function util.calcAbsoluteWidths(relativeWidths, width)
    local absoluteWidths = {}
    local n = #relativeWidths
    local totalWidth = width or style.CONTENT_WIDTH
    for i, value in pairs(relativeWidths) do
        absoluteWidths[i] = (value * totalWidth) - (style.SAMELINE_SPACING/n)
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
    for i, value in pairs(oldTable) do
        if params then
            newTable[i] = func(value, table.unpack(params))
        else
            newTable[i] = func(value)
        end
    end
    return newTable
end

function util.uniqueBy(t, attribute)
    local hash = {}
    local res = {}

    for _,v in ipairs(t) do
        local key = attribute and v[attribute] or v
        if (not hash[key]) then
            res[#res+1] = v
            hash[key] = true
        end
    end

    return res
end

function util.filter(t, condition)
    local filtered = {}
    for key, value in pairs(t) do
        if condition(key, value) then table.insert(filtered, value) end
    end
    return filtered
end

function util.mergeUnique(t1, t2, keysToCompare)
    local hash = {}
    local newTable = {}

    for _, t in pairs({t1, t2}) do
        for _, element in pairs(t) do
            -- You can't directly set the table as the hash value, since tables
            -- are compared by reference and everything with tables is pass by reference
            local hashValue = ""
            for _, key in pairs(keysToCompare) do
                hashValue = hashValue .. element[key] .. "|"
            end

            if not hash[hashValue] then
                table.insert(newTable, element)
                hash[hashValue] = true
            end
        end
    end

    return newTable
end
