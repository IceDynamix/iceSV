function editor.placeElements(elements, type)
    if #elements == 0 then return end
    local status = "Inserted " .. #elements .. " "
    if not type or type == 0 then
        actions.PlaceScrollVelocityBatch(elements)
        status = status .. "SVs"
    elseif type == 1 then
        actions.PlaceHitObjectBatch(elements)
        status = status .. "notes"
    elseif type == 2 then
        actions.PlaceTimingPointBatch(elements)
        status = status .. "BPM Points"
    end
    statusMessage = status .. "!"
end

editor.typeAttributes = {
    -- SV
    [0] = {
        "StartTime",
        "Multiplier"
    },
    -- "Note"
    [1] = {
        "StartTime",
        "Lane",
        "EndTime",
        -- "HitSound", left out because there's some trouble with comparing hitsound values
        "EditorLayer"
    },
    -- BPM
    [2] = {
        "StartTime",
        "Bpm",
        -- "Signature", same reason
    }
}

function editor.createNewTableOfElements(elements, typeMode, settings)
    local newTable = {}

    for _, element in pairs(elements) do
        local newElement = {}
        for _, attribute in pairs(editor.typeAttributes[typeMode]) do
            if settings[attribute] then
                newElement[attribute] = settings[attribute](element[attribute])
            else
                newElement[attribute] = element[attribute]
            end
        end

        table.insert(newTable, newElement)
    end

    local newElements = {}

    for _, el in pairs(newTable) do
        if typeMode == 0 then
            table.insert(newElements, utils.CreateScrollVelocity(el.StartTime, el.Multiplier))
        elseif typeMode == 1 then
            table.insert(newElements, utils.CreateHitObject(el.StartTime, el.Lane, el.EndTime, nil))
        elseif typeMode == 2 then
            table.insert(newElements, utils.CreateTimingPoint(el.StartTime, el.Bpm, nil))
        end
    end

    return newElements
end
